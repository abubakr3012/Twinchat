from django.contrib import admin
from .models import Contact


@admin.register(Contact)
class ContactAdmin(admin.ModelAdmin):

    list_display = [
        'id',
        'owner',
        'contact',
        'nickname',
        'is_blocked',
        'added_at',
    ]

    list_filter = [
        'is_blocked',
        'added_at',
    ]

    search_fields = [
        'owner__username',
        'contact__username',
        'nickname',
    ]

    readonly_fields = ['added_at']