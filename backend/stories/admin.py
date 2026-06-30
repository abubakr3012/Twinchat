from django.contrib import admin
from .models import Story, StoryView


@admin.register(Story)
class StoryAdmin(admin.ModelAdmin):

    list_display = [
        'id',
        'user',
        'media_type',
        'created_at',
        'expires_at',
    ]

    list_filter = [
        'media_type',
        'created_at',
    ]

    search_fields = [
        'user__username',
    ]

    readonly_fields = ['created_at', 'expires_at']


@admin.register(StoryView)
class StoryViewAdmin(admin.ModelAdmin):

    list_display = [
        'id',
        'story',
        'viewer',
        'viewed_at',
    ]

    search_fields = [
        'viewer__username',
    ]

    readonly_fields = ['viewed_at']