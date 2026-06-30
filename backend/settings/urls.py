from django.urls import path
from .views import (
    ChatSettingsView,
    PrivacyView,
    AppLanguageView,
)

urlpatterns = [
    path('chat/', ChatSettingsView.as_view(), name='settings-chat'),
    path('privacy/', PrivacyView.as_view(), name='settings-privacy'),
    path('language/', AppLanguageView.as_view(), name='settings-language'),
]