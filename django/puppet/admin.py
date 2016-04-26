from django.contrib import admin

# Register your models here.
from .models import User
from .models import Host
from .models import PuppetClass


class HostAdmin(admin.ModelAdmin):
    list_filter = ['puppet_classes', 'loginid__ou', 'loginid']


class UserAdmin(admin.ModelAdmin):
    list_filter = ['ou', 'departmental_account']


admin.site.register(User, UserAdmin)
admin.site.register(Host, HostAdmin)
admin.site.register(PuppetClass)
