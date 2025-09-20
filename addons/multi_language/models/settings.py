# -*- coding: utf-8 -*-
from odoo import api, fields, models, _


class ResConfigSettings(models.TransientModel):
    _inherit = 'res.config.settings'

    default_greeting = fields.Char(
        string='Default Greeting',
        help='Default greeting used by the Multi Language demo',
        config_parameter='multi_language.default_greeting',
        default='Hello'
    )
