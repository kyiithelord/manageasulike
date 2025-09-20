# -*- coding: utf-8 -*-
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2025 akyii
from odoo import api, fields, models, _


class ResConfigSettings(models.TransientModel):
    _inherit = 'res.config.settings'

    default_greeting = fields.Char(
        string='Default Greeting',
        help='Default greeting used by the Multi Language demo',
        config_parameter='multi_language.default_greeting',
        default='Hello'
    )
