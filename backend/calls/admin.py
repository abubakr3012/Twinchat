from django.contrib import admin
from .models import Call, CallParticipant


@admin.register(Call)
class CallAdmin(admin.ModelAdmin):

    list_display = [
        'id',
        'chat',
        'initiator',
        'call_type',
        'status',
        'started_at',
        'ended_at',
        'created_at',
    ]

    list_filter = [
        'call_type',
        'status',
        'created_at',
    ]

    search_fields = [
        'initiator__username',
    ]

    readonly_fields = ['created_at']


@admin.register(CallParticipant)
class CallParticipantAdmin(admin.ModelAdmin):

    list_display = [
        'id',
        'call',
        'user',
        'joined_at',
        'left_at',
    ]

    search_fields = [
        'user__username',
    ]