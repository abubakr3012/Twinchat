from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from rest_framework.permissions import AllowAny 

urlpatterns = [
    path('api/schema/', SpectacularAPIView.as_view(permission_classes=[AllowAny]), name='schema'),  
    path('api/swagger/', SpectacularSwaggerView.as_view(permission_classes=[AllowAny], url_name='schema'), name='swagger-ui'),
    path('admin/', admin.site.urls),
    path('', include('users.urls')),
    path('chats/', include('chats.urls')),
    path('messages/', include('chat_messages.urls')),
    path('contacts/', include('contacts.urls')),
    path('attachments/', include('attachments.urls')),
    path('reactions/', include('reactions.urls')),
    path('settings/', include('settings.urls')),
    path('calls/', include('calls.urls')),
    path('stories/', include('stories.urls')),
    path('encryption/', include('encryption.urls')),
]