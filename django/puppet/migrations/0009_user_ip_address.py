# -*- coding: utf-8 -*-
# Generated by Django 1.9.4 on 2016-03-21 21:46
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('puppet', '0008_auto_20160321_1440'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='ip_address',
            field=models.GenericIPAddressField(default=''),
            preserve_default=False,
        ),
    ]
