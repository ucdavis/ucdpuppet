# -*- coding: utf-8 -*-
# Generated by Django 1.9.4 on 2016-03-18 20:35
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('puppet', '0003_auto_20160318_2031'),
    ]

    operations = [
        migrations.AlterField(
            model_name='puppetclass',
            name='description',
            field=models.TextField(max_length=500),
        ),
    ]