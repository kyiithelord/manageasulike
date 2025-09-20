# -*- coding: utf-8 -*-
from odoo import api, fields, models, _


class MultiLanguageDemo(models.Model):
    _name = 'multi.language.demo'
    _description = 'Multi Language Demo'

    name = fields.Char(string='Name', required=True, translate=True)
    message_count = fields.Integer(string='Message Count', default=0)

    def get_greeting(self):
        self.ensure_one()
        # Read default greeting from system parameters (set via settings)
        param = self.env['ir.config_parameter'].sudo().get_param('multi_language.default_greeting', default=_('Hello'))
        return _('%(greet)s, %(name)s!', greet=param, name=self.name)
