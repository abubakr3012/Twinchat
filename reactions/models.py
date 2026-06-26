from django.db import models
from django.conf import settings


class Reaction(models.Model):

    message = models.ForeignKey(
        'chat_messages.Message',
        on_delete=models.CASCADE,
        related_name='reactions'
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reactions'
    )

    emoji = models.CharField(
        max_length=10
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        unique_together = ('message', 'user', 'emoji')

    def __str__(self):
        return f'{self.user.username} — {self.emoji} on message {self.message.id}'