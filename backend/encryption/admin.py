from django.contrib import admin
from .models import SafeModeSession, SafeModeKeyShareLog, SafeModeUIState


@admin.register(SafeModeSession)
class SafeModeSessionAdmin(admin.ModelAdmin):

    list_display = [
        'id',
        'user',
        'key_fingerprint',
        'is_active',
        'created_at',
        'updated_at',
    ]

    list_filter = ['is_active']

    search_fields = ['user__username', 'key_fingerprint']

    readonly_fields = ['created_at', 'updated_at']


@admin.register(SafeModeKeyShareLog)
class SafeModeKeyShareLogAdmin(admin.ModelAdmin):

    list_display = [
        'id',
        'user',
        'shared_with',
        'method',
        'shared_at',
        'is_revoked',
    ]

    list_filter = ['method', 'is_revoked']

    search_fields = ['user__username', 'shared_with__username']

    readonly_fields = ['shared_at']


@admin.register(SafeModeUIState)
class SafeModeUIStateAdmin(admin.ModelAdmin):

    list_display = [
        'id',
        'user',
        'key_entered',
        'auto_lock_minutes',
        'updated_at',
    ]

    search_fields = ['user__username']

    readonly_fields = ['updated_at']