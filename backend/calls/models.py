from django.db import models
from django.conf import settings


class Call(models.Model):

    CALL_TYPES = (
        ('voice', 'Voice'),
        ('video', 'Video'),
    )

    CALL_STATUS = (
        ('ringing', 'Ringing'),
        ('active', 'Active'),
        ('ended', 'Ended'),
        ('missed', 'Missed'),
        ('rejected', 'Rejected'),
    )

    chat = models.ForeignKey(
        'chats.Chat',
        on_delete=models.CASCADE,
        related_name='calls'
    )

    initiator = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='initiated_calls'
    )

    call_type = models.CharField(
        max_length=20,
        choices=CALL_TYPES,
        default='voice'
    )

    status = models.CharField(
        max_length=20,
        choices=CALL_STATUS,
        default='ringing'
    )

    started_at = models.DateTimeField(
        null=True,
        blank=True
    )

    ended_at = models.DateTimeField(
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    def __str__(self):
        return f'{self.call_type} call — {self.status} ({self.chat})'


class CallParticipant(models.Model):

    call = models.ForeignKey(
        Call,
        on_delete=models.CASCADE,
        related_name='participants'
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='call_participations'
    )

    joined_at = models.DateTimeField(
        null=True,
        blank=True
    )

    left_at = models.DateTimeField(
        null=True,
        blank=True
    )

    class Meta:
        unique_together = ('call', 'user')

    def __str__(self):
        return f'{self.user.username} in call {self.call.id}'