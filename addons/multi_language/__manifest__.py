# -*- coding: utf-8 -*-
{
    'name': 'Multi Language',
    'summary': 'Demonstration of i18n (translations) for multilingual users',
    'description': 'Provides a minimal controller and strings to demonstrate Odoo translation (i18n) support.',
    'version': '18.0.2.0.0',
    'author': 'akyii',
    'license': 'LGPL-3',
    'category': 'Tools',
    'depends': ['base', 'web'],
    'data': [
        'security/ir.model.access.csv',
        'views/multi_language_views.xml',
        'views/res_config_settings_views.xml',
        'views/multi_language_templates.xml',
    ],
    'assets': {},
    'installable': True,
    'application': False,
}
