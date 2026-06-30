from django.contrib import admin
from .models import Message


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'chat',
        'sender',
        'message_type',
        'is_edited',
        'is_deleted',
        'created_at',
    )

    list_filter = (
        'message_type',
        'is_edited',
        'is_deleted',
        'created_at',
    )

    search_fields = (
        'content',
        'sender__username',
        'chat__id',
    )

    readonly_fields = (
        'created_at',
        'updated_at',
    )

    fieldsets = (
        (
            'Основное',
            {
                'fields': (
                    'chat',
                    'sender',
                    'content',
                    'message_type',
                )
            }
        ),

        (
            'Статус',
            {
                'fields': (
                    'is_edited',
                    'is_deleted',
                )
            }
        ),

        (
            'Время',
            {
                'fields': (
                    'created_at',
                    'updated_at',
                )
            }
        ),
    )