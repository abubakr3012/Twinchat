from django.contrib import admin
from .models import Reaction


@admin.register(Reaction)
class ReactionAdmin(admin.ModelAdmin):

    list_display = [
        'id',
        'message',
        'user',
        'emoji',
        'created_at',
    ]

    list_filter = [
        'emoji',
        'created_at',
    ]

    search_fields = [
        'user__username',
        'emoji',
    ]

    readonly_fields = ['created_at']