from django.conf.urls import url

from . import views

urlpatterns = [
    url(r'^class/([^/]+)/?$', views.puppet_class, name='puppet_class'),
    url(r'^edit/([^/]+)/?$', views.edit_host, name='edit-host'),
    url(r'^delete/([^/]+)/?$', views.delete_host, name='delete-host'),
    url(r'^user/(?P<loginid>[^/]+)/?$', views.edit_user, name='edit-user'),
    #url(r'^add-host', views.add_host, name='add-host'),
    url(r'^', views.index, name='index'),
]
