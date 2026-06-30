from django.db import models
from django.conf import settings


class Chat(models.Model):

    CHAT_TYPES = (
        ('private', 'Private'),
        ('group', 'Group'),
    )

    type = models.CharField(
        max_length=20,
        choices=CHAT_TYPES,
        default='private'
    )

    name = models.CharField(
        max_length=255,
        null=True,
        blank=True
    )

    avatar = models.ImageField(
        upload_to='media/chat_avatars/',
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    updated_at = models.DateTimeField(
        auto_now=True
    )


    def __str__(self):
        return self.name or f"Chat {self.id}"

class ChatMember(models.Model):

    chat = models.ForeignKey(
        Chat,
        on_delete=models.CASCADE,
        related_name='members'
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='chat_memberships'
    )

    is_admin = models.BooleanField(
        default=False
    )

    joined_at = models.DateTimeField(
        auto_now_add=True
    )


    class Meta:
        unique_together = ('chat', 'user')