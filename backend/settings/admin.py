from django.contrib import admin
from .models import ChatSettings, Privacy, AppLanguage


@admin.register(ChatSettings)
class ChatSettingsAdmin(admin.ModelAdmin):

    list_display = [
        'id',
        'user',
        'theme',
        'text_size',
        'notifications',
    ]

    search_fields = ['user__username']


@admin.register(Privacy)
class PrivacyAdmin(admin.ModelAdmin):

    list_display = [
        'id',
        'user',
        'see_phone_number',
        'see_profile_photo',
        'see_last_seen',
        'two_factor_auth',
    ]

    search_fields = ['user__username']


@admin.register(AppLanguage)
class AppLanguageAdmin(admin.ModelAdmin):

    list_display = [
        'id',
        'user',
        'language',
        'auto_translate',
    ]

    search_fields = ['user__username']