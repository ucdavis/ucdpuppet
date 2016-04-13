import traceback
from django.template.response import TemplateResponse
from django.shortcuts import render, get_object_or_404, redirect, HttpResponse
import django.forms
from django.contrib import messages
import django.core.exceptions
import django.http

import subprocess
import datetime
import ipware.ip

from .models import *


def run_command(args):
    p = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return p.communicate()


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


def get_user(request):
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
    fqdn = formset['fqdn'].value()

    # Before the host gets saved to the database, make sure it has been signed by Puppet
    out, err = run_command(['/usr/bin/sudo', '/opt/puppetlabs/bin/puppet', 'cert', 'list', '--color=false', fqdn])

    if err and err.startswith('Error: Could not find a certificate for'):
        messages.warning(request,
                         'The Puppet Server was unable to find a certificate signing request from <tt>%s</tt>.<br/>Did you run <tt>%s</tt>?' % (
                             fqdn, puppet_run_command),
                         extra_tags='safe')
        return False
    elif err:
        msg_admins(request, 'Received error trying to list the certificate:<pre>%s</pre><pre>%s</pre>' % (out, err))
        return False

    # + "kona.cse.ucdavis.edu" (SHA256) B4:61:67:48:5A:02:88:B1:7E:D0:4C:6C:C4:CD:BB:4F:16:94:D6:62:F7:23:28:02:78:C7:B7:A5:A0:1D:C0:87
    data = out.split()

    if data[0] == '+':
        msg_admins(request, 'A certificate for this FQDN is already signed:<pre>%s</pre>' % out)
        return False

    if data[2] != formset['hash'].value():
        messages.error(request, 'Your specified hash does not match the hash Puppet has for your host.')
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
        new_host = formset.save(commit=True)
        new_host.loginid = user
        new_host.save()
    except:
        messages_traceback(request)
        # If there is a write error in the YAML in formset.save(commit=True) then we need to delete the object that gets saved to the database.
        Host.objects.get(fqdn=fqdn).delete()

    messages.success(request,
                     "Host %s added to your profile. You can run <tt>%s</tt> to apply the classes immediately." % (new_host.fqdn, puppet_run_command),
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


def index(request, edit_existing=None):
    user, previous_login, previous_ip, err = get_user(request)
    if err:
        return err

    formset = host_form = django.forms.models.modelform_factory(Host, form=HostAddForm)

    if request.method == 'POST' and 'add-host' in request.POST:
        formset = host_form(request.POST)
        if formset.is_valid():
            status = validate_host(request, formset, user)
            if status:
                return status
        else:
            messages.error(request, 'Unable to add host, please fix the errors below.')

    elif request.method == 'POST' and 'edit-host' in request.POST:
        host = get_object_or_404(Host, loginid=user, fqdn=request.POST['fqdn'])

        p_c = PuppetClass.objects.filter(pk__in=request.POST.getlist('puppet_classes'))
        host.puppet_classes = p_c
        try:
            host.save()
        except:
            messages_traceback(request)
        else:
            messages.success(request,
                             "Updated host %s. Run <tt>%s</tt> to immediately update your host." % (host.fqdn, puppet_run_command),
                             extra_tags='safe')
            return redirect('index')

    elif edit_existing:
        # edit_host() takes care of making sure that the host exists and belongs to the user
        host_form = django.forms.models.modelform_factory(Host, form=HostAddForm, fields=('fqdn', 'puppet_classes',),
                                                          widgets={'fqdn': django.forms.HiddenInput()})
        formset = host_form(None, instance=edit_existing)

    hosts = Host.objects.filter(loginid=user)

    return render(request,
                  'puppet/user.html',
                  {'hosts': hosts,
                   'user': user,
                   'previous_login': previous_login,
                   'previous_ip': previous_ip,
                   'formset': formset,
                   'edit': edit_existing,
                   'puppet_classes': PuppetClass.objects.all(),
                   'puppet_run_command': puppet_run_command,
                   }
                  )


def edit_host(request, fqdn):
    user, previous_login, previous_ip, err = get_user(request)
    if err:
        return err

    host = get_object_or_404(Host, fqdn=fqdn, loginid=user)

    return index(request, edit_existing=host)


def delete_host(request, fqdn):
    user, previous_login, previous_ip, err = get_user(request)
    if err:
        return err

    host = get_object_or_404(Host, fqdn=fqdn, loginid=user)

    host.delete()
    out, err = run_command(['/usr/bin/sudo', '/opt/puppetlabs/bin/puppet', 'cert', 'clean', '--color=false', fqdn])
    messages.success(request, 'Host %s deleted.<br/><pre>%s</pre>' % (host.fqdn, out), extra_tags='safe')

    return redirect('index')


def puppet_class(request, name):
    pc = get_object_or_404(PuppetClass, display_name=name)

    return render(request,
                  'puppet/class.html',
                  {'pc': pc},
                  )
