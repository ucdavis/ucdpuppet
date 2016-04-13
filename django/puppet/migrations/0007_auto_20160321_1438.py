# -*- coding: utf-8 -*-
# Generated by Django 1.9.4 on 2016-03-21 21:38
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('puppet', '0006_auto_20160318_2038'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='host',
            options={'ordering': ['fqdn']},
        ),
        migrations.AlterField(
            model_name='user',
            name='email_address',
            field=models.EmailField(db_index=True, max_length=254),
        ),
        migrations.AlterField(
            model_name='user',
            name='last_login_date',
            field=models.DateTimeField(auto_created=True),
        ),
    ]
