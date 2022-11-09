# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

from django.views.generic import TemplateView


class AppView(TemplateView):
    template_name = 'index.html'

    def get(self, request, *args, **kwargs):
        # Make sure logged-in
        context = self.get_context_data(**kwargs)
        return self.render_to_response(context)
