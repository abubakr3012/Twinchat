from django.contrib import admin

from .models import Chat, ChatMember



@admin.register(Chat)
class ChatAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'type',
        'name',
        'created_at',
        'updated_at',
    )

    list_filter = (
        'type',
        'created_at',
    )

    search_fields = (
        'name',
    )

    readonly_fields = (
        'created_at',
        'updated_at',
    )

    fieldsets = (
        (
            'Основная информация',
            {
                'fields': (
                    'type',
                    'name',
                    'avatar',
                )
            }
        ),

        (
            'Даты',
            {
                'fields': (
                    'created_at',
                    'updated_at',
                )
            }
        ),
    )



@admin.register(ChatMember)
class ChatMemberAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'chat',
        'user',
        'is_admin',
        'joined_at',
    )

    list_filter = (
        'is_admin',
        'joined_at',
    )

    search_fields = (
        'user__username',
        'chat__name',
    )

    readonly_fields = (
        'joined_at',
    )

    fieldsets = (
        (
            'Участник',
            {
                'fields': (
                    'chat',
                    'user',
                    'is_admin',
                )
            }
        ),

        (
            'Дата вступления',
            {
                'fields': (
                    'joined_at',
                )
            }
        ),
    )