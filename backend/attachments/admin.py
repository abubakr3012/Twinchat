from django.contrib import admin
from .models import Attachment


@admin.register(Attachment)
class AttachmentAdmin(admin.ModelAdmin):

    list_display = [
        'id',
        'message',
        'file_type',
        'file_name',
        'file_size',
        'created_at',
    ]

    list_filter = [
        'file_type',
        'created_at',
    ]

    search_fields = [
        'file_name',
        'message__sender__username',
    ]

    readonly_fields = ['created_at']