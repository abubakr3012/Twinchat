from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import User, Profile


@admin.register(User)
class CustomUserAdmin(UserAdmin):

    list_display = (
        'id',
        'username',
        'email',
        'phone_number',
        'is_online',
        'is_staff',
        'created_at',
    )

    list_filter = (
        'is_online',
        'is_staff',
        'is_superuser',
        'created_at',
    )

    search_fields = (
        'username',
        'email',
        'phone_number',
    )

    readonly_fields = (
        'created_at',
        'updated_at',
        'last_login',
    )

    fieldsets = (
        (
            'Основная информация',
            {
                'fields': (
                    'username',
                    'password',
                    'email',
                    'phone_number',
                    'avatar',
                    'bio',
                )
            }
        ),

        (
            'Статус',
            {
                'fields': (
                    'is_online',
                    'last_seen',
                )
            }
        ),

        (
            'Шифрование',
            {
                'fields': (
                    'public_key',
                    'key_fingerprint',
                )
            }
        ),

        (
            'Права доступа',
            {
                'fields': (
                    'is_active',
                    'is_staff',
                    'is_superuser',
                    'groups',
                    'user_permissions',
                )
            }
        ),

        (
            'Даты',
            {
                'fields': (
                    'last_login',
                    'created_at',
                    'updated_at',
                )
            }
        ),
    )



@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'user',
        'nickname',
        'birthday',
    )

    search_fields = (
        'user__username',
        'nickname',
    )

    list_filter = (
        'birthday',
    )