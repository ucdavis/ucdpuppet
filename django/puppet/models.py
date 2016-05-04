from __future__ import unicode_literals

from django.db import models
from django.core.exceptions import ValidationError
import django
import django.forms
import django.core.validators

import re
import os

from .utils import *

puppet_run_command = 'sudo /opt/puppetlabs/bin/puppet agent --test --server=puppet.ucdavis.edu'
puppet_run_command_initial = puppet_run_command + ' --waitforcert 0'

ucdpuppet_dir = '/etc/puppetlabs/code/environments/production/modules/ucdpuppet'

sha256_re = re.compile(r'^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){31}$')

def validate_hash(value):
    if not re.match(sha256_re, value):
        raise ValidationError('%(value)s does not look like a valid SHA256 hash',
                              params={'value': value},
                              )


HOSTNAME_LABEL_PATTERN = re.compile("(?!-)[A-Z\d-]+(?<!-)$", re.IGNORECASE)

def full_domain_validator(hostname):
    """
    OW: originally from: http://stackoverflow.com/questions/17821400/regex-match-for-domain-name-in-django-model
    Fully validates a domain name as compilant with the standard rules:
        - Composed of series of labels concatenated with dots, as are all domain names.
        - Each label must be between 1 and 63 characters long.
        - The entire hostname (including the delimiting dots) has a maximum of 255 characters.
        - Only characters 'a' through 'z' (in a case-insensitive manner), the digits '0' through '9'.
        - Labels can't start or end with a hyphen.
    """
    if not hostname:
        return

    if len(hostname) > 255:
        raise ValidationError('The domain name cannot be composed of more than 255 characters.')

    if hostname[-1:] == ".":
        hostname = hostname[:-1]  # strip exactly one dot from the right, if present

    if re.match(r"[\d.]+$", hostname):
        raise ValidationError('You must provide a FQDN, not an IP address.')

    split = hostname.split(".")
    if len(split) < 3:
        raise ValidationError('FQDN must consist of 3 or more pieces.')

    for label in split:
        if len(label) > 63:
            raise ValidationError('The label \'%(label)s\' is too long (maximum is 63 characters).' % {'label': label})
        if not HOSTNAME_LABEL_PATTERN.match(label):
            raise ValidationError('Unallowed characters in label: %(label)s' % {'label': label})


class User(models.Model):
    loginid = models.CharField(max_length=16, db_index=True, unique=True)
    display_name = models.CharField(max_length=200)
    ou = models.CharField(max_length=200, verbose_name=" OU")
    mail = models.EmailField(db_index=True, validators=[django.core.validators.EmailValidator])

    last_login = models.DateTimeField()
    ip_address = models.GenericIPAddressField()

    departmental_account = models.BooleanField(default=False)

    class Meta:
        ordering = ['display_name']

    class UCDLDAPError(Exception):
        pass

    @classmethod
    def create(cls, loginid):
        import ldap
        l = ldap.initialize("ldaps://ldap.ucdavis.edu")

        baseDN = "ou=People,dc=ucdavis,dc=edu"
        searchScope = ldap.SCOPE_SUBTREE

        retrieveAttributes = None
        searchFilter = "uid=%s" % loginid

        ldap_result_id = l.search(baseDN, searchScope, searchFilter, retrieveAttributes)
        result_set = []
        while 1:
            result_type, result_data = l.result(ldap_result_id, 0)
            if (result_data == []):
                break
            else:
                ## here you don't have to append to a list
                ## you could do whatever you want with the individual entry
                ## The appending to list is just for illustration.
                if result_type == ldap.RES_SEARCH_ENTRY:
                    result_set.append(result_data)
        # except ldap.LDAPError as e:
        #     raise User.UCDLDAPError(e.args)

        # result_set ::
        # a = [[('ucdPersonUUID=00457597,ou=People,dc=ucdavis,dc=edu',
        #    {'telephoneNumber': ['+1 530 752 1130'], 'departmentNumber': ['030250'], 'displayName': ['Omen Wild'],
        #     'cn': ['Omen Wild'], 'title': ['Systems Administrator'], 'eduPersonAffiliation': ['staff'],
        #     'ucdPersonUUID': ['00457597'], 'l': ['Davis'], 'st': ['CA'], 'street': ['148 Hoagland Hall'],
        #     'sn': ['Wild'], 'postalCode': ['95616'], 'mail': ['omen@ucdavis.edu'],
        #     'postalAddress': ['148 Hoagland Hall$Davis, CA 95616'], 'givenName': ['Omen'], 'ou': ['Metro Cluster'],
        #     'uid': ['omen']})]]

        try:
            displayName = result_set[0][0][1]['displayName'][0]
            mail = result_set[0][0][1]['mail'][0]
            ou = result_set[0][0][1]['ou'][0]
        except:
            raise User.UCDLDAPError('Error looking up LDAP Attributes for %s' % loginid)

        return cls(loginid=loginid, display_name=displayName, mail=mail, ou=ou)


    def __str__(self):
        return "%s <%s>" % (self.display_name, self.mail)


class UserEditForm(django.forms.ModelForm):
    class Meta:
        model = User
        fields = ['display_name', 'ou', 'mail']
        help_texts = {
            'display_name': 'The name of your IT group, or the main IT person associated with this departmental account.',
            'ou': 'Your official UCD Organizational Unit name.',
            'mail': 'An email address to contact your IT team.'
        }
        widgets = {  # 'loginid': django.forms.HiddenInput(),
            'display_name': django.forms.TextInput(attrs={'size': 55}),
            'ou': django.forms.TextInput(attrs={'size': 55}),
            'mail': django.forms.TextInput(attrs={'size': 55}),
        }


class PuppetClass(models.Model):
    display_name = models.CharField(max_length=128, unique=True)
    class_name = models.CharField(max_length=128, unique=True)
    description = models.TextField(max_length=500)
    argument_allowed = models.BooleanField(default=False)
    argument = models.CharField(max_length=200, blank=True, default='')

    def __str__(self):
        return self.display_name

    class Meta:
        ordering = ['display_name']

    def full_puppet_class_name(self):
        return 'ucdpuppet::%s' % self.class_name


class Host(models.Model):
    loginid = models.ForeignKey(User, null=True)
    hash = models.CharField(max_length=128, validators=[validate_hash])
    fqdn = models.CharField(max_length=255, unique=True, verbose_name=" FQDN", validators=[full_domain_validator])
    puppet_classes = models.ManyToManyField(PuppetClass)
    last_update_date = models.DateTimeField(auto_now=True)

    ### The directory the Puppet YAML files get written into.
    yaml_base = '/etc/puppetlabs/code/hieradata/nodes/'

    class Meta:
        ordering = ['fqdn']


    def __str__(self):
        if self.loginid and self.loginid.mail:
            email = self.loginid.mail
        else:
            email = "ORPHANED"
        return "%s (%s) by %s" % (self.fqdn, ", ".join(p.display_name for p in self.puppet_classes.all()), email)


    def yaml_file(self):
        return os.path.join(self.yaml_base, self.fqdn + '.yaml')


    def save(self, *args, **kwargs):
        super(Host, self).save(*args, **kwargs)
        self.write_yaml()


    def write_yaml(self):
        with open(self.yaml_file(), 'w') as f:
            f.write("classes:\n")
            for puppet_class in self.puppet_classes.all():
                f.write(" - %s\n" % puppet_class.full_puppet_class_name())


    def delete(self, *args, **kwargs):
        if os.path.isfile(self.yaml_file()):
            os.unlink(self.yaml_file())

        fqdn = self.fqdn

        super(Host, self).delete()

        return run_command(['/usr/bin/sudo', '/opt/puppetlabs/bin/puppet', 'cert', 'clean', '--color=false', fqdn])


class HostAddForm(django.forms.ModelForm):
    class Meta:
        model = Host
        fields = ['fqdn', 'hash', 'puppet_classes']
        help_texts = {
            'fqdn': 'The FQDN of the host, as shown by: <tt>/opt/puppetlabs/bin/facter fqdn</tt>',
            'hash': 'The SHA256 hash shown during the first run of: <tt>%s</tt>' % puppet_run_command_initial,
        }
        widgets = {'hash': django.forms.TextInput(attrs={'size': 98}),
                   'fqdn': django.forms.TextInput(attrs={'size': 55})}
