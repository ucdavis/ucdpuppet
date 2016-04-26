# -*- coding: utf-8 -*-
# Generated by Django 1.9.4 on 2016-03-24 22:50
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('puppet', '0019_auto_20160323_1106'),
    ]

    operations = [
        migrations.RenameField(
            model_name='user',
            old_name='email_address',
            new_name='mail',
        ),
        migrations.AddField(
            model_name='user',
            name='ou',
            field=models.CharField(default='abcd', max_length=200),
            preserve_default=False,
        ),
    ]