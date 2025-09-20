# -*- coding: utf-8 -*-
from odoo import http, _
from odoo.http import request


class MultiLanguageController(http.Controller):
    @http.route(['/ml_hello'], type='http', auth='public')
    def hello_page(self, **kwargs):
        # Optional query parameters
        name = kwargs.get('name') or 'User'
        # Demonstrate pluralization with a count query param
        try:
            count = int(kwargs.get('count', 1))
        except Exception:
            count = 1

        # Set context language from ?lang= if provided (for demo/testing)
        lang = kwargs.get('lang')
        if lang:
            request.context = dict(request.context or {}, lang=lang)

        # Example Python-side translatable message with placeholders
        python_message = _('%(greet)s, %(name)s!', greet=_('Hello'), name=name)

        # Example pluralized message
        # Note: Odoo's _() supports plural via ngettext semantics when defined in .po
        # For demo, we provide two msgids in .po via hints; here we choose by count.
        if count == 1:
            plural_message = _('You have %(n)d message') % {'n': count}
        else:
            plural_message = _('You have %(n)d messages') % {'n': count}

        return request.render('multi_language.hello_page', {
            'python_message': python_message,
            'plural_message': plural_message,
            'name': name,
            'count': count,
        })

    @http.route(['/ml_api/hello'], type='json', auth='public', cors='*')
    def api_hello(self, **kwargs):
        # Determine language: ?lang= overrides Accept-Language for demo
        lang = (kwargs.get('lang')
                or request.httprequest.headers.get('Accept-Language', '').split(',')[0]
                or request.env.user.lang)
        if lang:
            request.context = dict(request.context or {}, lang=lang)
        name = kwargs.get('name') or 'User'
        msg = _('%(greet)s, %(name)s!') % {'greet': _('Hello'), 'name': name}
        return {
            'message': msg,
            'lang': lang,
        }
