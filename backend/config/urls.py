from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from rest_framework.permissions import AllowAny 
from rest_framework_simplejwt.views import TokenRefreshView
from django.conf.urls.static import static
from django.conf import settings


urlpatterns = [
    path('api/schema/', SpectacularAPIView.as_view(permission_classes=[AllowAny]), name='schema'),
    path('api/swagger/', SpectacularSwaggerView.as_view(permission_classes=[AllowAny], url_name='schema'), name='swagger-ui'),
    path('admin/', admin.site.urls),
    path('api/auth/token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('api/users/', include('users.urls')),
    path('api/chats/', include('chats.urls')),
    path('api/messages/', include('chat_messages.urls')),
    path('api/contacts/', include('contacts.urls')),
    path('api/attachments/', include('attachments.urls')),
    path('api/reactions/', include('reactions.urls')),
    path('api/settings/', include('settings.urls')),
    path('api/calls/', include('calls.urls')),
    path('api/stories/', include('stories.urls')),
    path('api/encryption/', include('encryption.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)