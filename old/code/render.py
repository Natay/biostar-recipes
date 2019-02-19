import os

import django
from django.conf import settings
from django.template import loader

__DIR = os.path.dirname(__file__)
LOCAL_TEMPLATES = os.path.join(__DIR, "templates")


def setup():
    '''
    Specify template engine and template directory.
    Pass the settings variable to configure.
    '''

    TEMPLATES = [
        {
            'BACKEND': 'django.template.backends.django.DjangoTemplates',
            'DIRS': [LOCAL_TEMPLATES],
            'OPTIONS': {
                'string_if_invalid': "** MISSING **",
                'libraries': {
                    'igv': 'recipes.code.igv',
                }
            },
        }
    ]
    settings.configure(TEMPLATES=TEMPLATES)
    django.setup()
    return


def render_template(name, context):
    """
    Renders the named template with the context dictionary
    via the django template loading.
    """
    setup()
    template = loader.get_template(name)
    result = template.render(context)
    return result


if __name__ == "__main__":
    name = "hello.html"
    data = dict(name="Jane")
    html = render_template(data, name)

    print(html)
