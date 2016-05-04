import traceback
from django.template.response import TemplateResponse
from django.shortcuts import render, get_object_or_404, redirect, HttpResponse
import django.forms
from django.contrib import messages
import django.core.exceptions
import django.http
from django.db import transaction

import datetime
import ipware.ip

from .models import *
from .utils import *

def get_current_git_commit():
    out, err = run_command(['/usr/bin/git', 'rev-parse', 'HEAD'], cwd=ucdpuppet_dir)
    return out


def messages_traceback(request, comment=None):
    base = 'Sorry, a serious error occurred, please copy this box and send it to <tt>ucd-puppet-admins@ucdavis.edu</tt>'

    if comment:
        base = base + '<br/>' + comment

    messages.error(request, base + '<br/><pre>' + traceback.format_exc() + '</pre>', extra_tags='safe')


def msg_admins(request, str):
    contact_admins = '<p>If you do not know how to resolve this error please email ucd dash puppet dash admins at ucdavis dot edu.</p>'
    messages.error(request, str + contact_admins, extra_tags='safe')


def get_loginid(request):
    if request.user.is_superuser:
        return request.user.username
    else:
        return request.META['REMOTE_USER']


def get_user_info(request):
    previous_login = None
    previous_ip = None
    user = None

    try:
        loginid = get_loginid(request)
        user = User.objects.get(loginid=loginid)

        previous_login = user.last_login
        previous_ip = user.ip_address
    except User.DoesNotExist:
        try:
            user = User.create(request.META['REMOTE_USER'])
        except User.UCDLDAPError:
            return (None, None, None,
                    redirect('edit-user', loginid=loginid))
    except KeyError as e:
        if e.args[0] == 'REMOTE_USER':
            return (None, None, None,
                    TemplateResponse(request, 'puppet/403.html',
                                     {'error': 'You must login via CAS to access this site.'}, status=403))
        else:
            return (None, None, None,
                    TemplateResponse(request, 'puppet/401.html', {'error': '%s: %s' % (type(e), e)}, status=401))
    except Exception as e:
        messages_traceback(request)
        return (None, None, None,
                TemplateResponse(request, 'puppet/401.html', {'error': 'Generic Error, the very best kind'},
                                 status=401))

    user.last_login = datetime.datetime.now()
    user.ip_address = ipware.ip.get_ip(request)
    user.save()

    return (user, previous_login, previous_ip, None)


def validate_host(request, formset, user):
    # Downcase it early as Puppet deals exclusively with lower case FQDNs
    fqdn = formset.cleaned_data['fqdn'] = formset.instance.fqdn = formset.cleaned_data['fqdn'].lower()

    # Before the host gets saved to the database, make sure it has been signed by Puppet
    out, err = run_command(['/usr/bin/sudo', '/opt/puppetlabs/bin/puppet', 'cert', 'list', '--color=false', fqdn])

    if err and err.startswith('Error: Could not find a certificate for'):
        messages.warning(request,
                         'The Puppet Server was unable to find a certificate signing request from <tt>%s</tt>.<br/>Did you run <tt>%s</tt>?' % (
                             fqdn, puppet['command_initial']),
                         extra_tags='safe')
        return False
    elif err:
        msg_admins(request, 'Received error trying to list the certificate:<pre>%s</pre><pre>%s</pre>' % (out, err))
        return False

    # + "kona.cse.ucdavis.edu" (SHA256) B4:61:67:48:5A:02:88:B1:7E:D0:4C:6C:C4:CD:BB:4F:16:94:D6:62:F7:23:28:02:78:C7:B7:A5:A0:1D:C0:87
    #   "millermr-dell-system-xps-l321x.ucdavis.edu" (SHA256) 19:F2:FA:FA:01:0D:36:51:F7:95:27:0B:95:86:2A:C6:EB:66:8B:F1:72:47:DF:1C:4C:1E:E4:72:AB:35:05:27

    data = out.strip().split()

    if data[0] == '+':
        msg_admins(request, 'A certificate for this FQDN is already signed:<pre>%s</pre>' % out)
        return False

    if data[0] == '-':
        msg_admins(request, "The certificate for this host has been revoked on the server. You may need to clear out Puppet's SSL directory <tt>%s</tt> and re-run the Puppet command <tt>%s</tt>." % (puppet['clear_certs'], puppet['command_initial']))
        return False

    if data[2] != formset.cleaned_data['hash']:
        msg_admins(request, 'Your specified hash does not match the hash Puppet has for your host.')
        return False

    if data[0] != '"' + fqdn + '"':
        msg_admins(request, 'Invalid output returned from Puppet:<br/><pre>%s</pre>' % out)
        return False

    out, err = run_command(['/usr/bin/sudo', '/opt/puppetlabs/bin/puppet', 'cert', 'sign', '--color=false', fqdn])
    if out and not out.startswith('Notice: Signed certificate request for'):
        msg_admins(request, 'Received unexpected output trying to sign the certificate: <br/>%s<br/>%s' % (out, err))
        return False
    if err:
        msg_admins(request, 'Received error trying to sign the certificate: <br/>%s<br/>%s' % (out, err))
        return False

    # Notice: Signed certificate request for puppet-test.metro.ucdavis.edu
    # Notice: Removing file Puppet::SSL::CertificateRequest puppet-test.metro.ucdavis.edu at '/etc/puppetlabs/puppet/ssl/ca/requests/puppet-test.metro.ucdavis.edu.pem'

    try:
        with transaction.atomic():
            new_host = formset.save(commit=True)
            new_host.loginid = user
            new_host.save()
    except:
        messages_traceback(request)
        # If there is a write error in the YAML in formset.save(commit=True) then we need to delete the object that gets saved to the database.
        Host.objects.get(fqdn=fqdn).delete()

    messages.success(request,
                     "Host %s added to your profile. Please run <tt>%s</tt> to finish you Puppet client configuration." % (new_host.fqdn, puppet['run_command']),
                     extra_tags='safe')

    # Redirect back to the index so the user gets a blank form, as well as make page reload not attempt to re-add the host.
    return redirect('index')


def edit_user(request, loginid):
    if loginid != get_loginid(request):
        return TemplateResponse(request, 'puppet/401.html', {'error': 'Looks like you are trying to mess with the LoginID. Bad dog, no cookie.'},
                                status=401)

    try:
        u = User.objects.get(loginid=loginid)
        return TemplateResponse(request, 'puppet/401.html',
                                {'error': 'You cannot edit LoginIDs once added.'},
                                status=401)
    except User.DoesNotExist:
        pass

    formset = django.forms.models.modelform_factory(User, form=UserEditForm)

    if request.method == 'POST' and 'edit-user' in request.POST:
        formset = formset(request.POST)
        if formset.is_valid():
            with transaction.atomic():
                user = formset.save(commit=False)
                user.loginid = loginid
                user.last_login = datetime.datetime.now()
                user.ip_address = ipware.ip.get_ip(request)
                user.departmental_account = True
                user.save()

            return redirect('index')
        else:
            messages.error(request, 'Unable to add user, please fix the errors below.')

    return render(request,
                  'puppet/edit-user.html',
                  {'formset': formset,
                   'loginid': loginid}
                  )


def index(request):
    user, previous_login, previous_ip, err = get_user_info(request)
    if err:
        return err

    return render(request,
                  'puppet/user.html',
                  {'hosts': Host.objects.filter(loginid=user),
                   'user': user,
                   'formset': django.forms.models.modelform_factory(Host, form=HostAddForm),
                   'previous_login': previous_login,
                   'previous_ip': previous_ip,
                   'puppet_classes': PuppetClass.objects.all(),
                   'puppet': puppet,
                   'git_commit': get_current_git_commit(),
                   }
                  )


def edit_host(request, fqdn=None):
    user, previous_login, previous_ip, err = get_user_info(request)
    if err:
        return err

    host = get_object_or_404(Host, fqdn=fqdn, loginid=user)

    if request.method == 'POST' and 'edit-host' in request.POST:
        p_c = PuppetClass.objects.filter(pk__in=request.POST.getlist('puppet_classes'))
        host.puppet_classes = p_c
        try:
            host.save()
        except:
            messages_traceback(request)
        else:
            messages.success(request,
                             "Updated host %s. Run <tt>%s</tt> to immediately update your host." % (
                             host.fqdn, puppet['run_command']),
                             extra_tags='safe')

            return redirect('index')

    host_form = django.forms.models.modelform_factory(Host, form=HostAddForm, fields=('fqdn', 'puppet_classes',),
                                                      widgets={'fqdn': django.forms.HiddenInput()})
    formset = host_form(None, instance=host)

    return render(request,
                  'puppet/user.html',
                  {'hosts': Host.objects.filter(loginid=user),
                   'user': user,
                   'formset': formset,
                   'previous_login': previous_login,
                   'previous_ip': previous_ip,
                   'edit': host,
                   'puppet_classes': PuppetClass.objects.all(),
                   'puppet': puppet,
                   'git_commit': get_current_git_commit(),
                   }
                  )


def add_host(request, fqdn=None):
    user, previous_login, previous_ip, err = get_user_info(request)
    if err:
        return err

    if request.method != 'POST' or 'add-host' not in request.POST:
        raise django.http.Http404()

    host_form = django.forms.models.modelform_factory(Host, form=HostAddForm)
    formset = host_form(request.POST)

    if formset.is_valid():
        status = validate_host(request, formset, user)
        if status:
            return status
    else:
        # formset not valid
        messages.error(request, 'Unable to add host, please fix the errors below.')

    return render(request,
                  'puppet/user.html',
                  {'hosts': Host.objects.filter(loginid=user),
                   'user': user,
                   'previous_login': previous_login,
                   'previous_ip': previous_ip,
                   'formset': formset,
                   'edit': edit_host,
                   'puppet_classes': PuppetClass.objects.all(),
                   'puppet': puppet,
                   'git_commit': get_current_git_commit(),
                   }
                  )


def delete_host(request, fqdn):
    user, previous_login, previous_ip, err = get_user_info(request)
    if err:
        return err

    host = get_object_or_404(Host, fqdn=fqdn, loginid=user)

    out, err = host.delete()
    if err:
        msg_admins(request, 'Received unexpected output running cert clean for %s: <br/>%s<br/>%s' % (fqdn, out, err))
    else:
        messages.success(request, 'Host %s deleted successfully and removed from UCD Puppet.<br/>' % host.fqdn, extra_tags='safe')

    return redirect('index')


def puppet_class(request, name):
    pc = get_object_or_404(PuppetClass, display_name=name)

    return render(request,
                  'puppet/class.html',
                  {'pc': pc},
                  )
