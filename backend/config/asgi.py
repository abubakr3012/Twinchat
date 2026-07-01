import os
import django
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

import chat_messages.routing
from config.jwt_middleware import JWTAuthMiddleware

application = ProtocolTypeRouter({
    'http': get_asgi_application(),
    'websocket': JWTAuthMiddleware(
        URLRouter(
            chat_messages.routing.websocket_urlpatterns
        )
    ),
})
