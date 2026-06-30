from django.db import models
from django.conf import settings


class Message(models.Model):

    MESSAGE_TYPES = (
        ('text', 'Text'),
        ('image', 'Image'),
        ('video', 'Video'),
        ('audio', 'Audio'),
        ('file', 'File'),
    )


    chat = models.ForeignKey(
        'chats.Chat',
        on_delete=models.CASCADE,
        related_name='messages'
    )


    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sent_messages'
    )


    content = models.TextField(
        blank=True,
        null=True
    )


    message_type = models.CharField(
        max_length=20,
        choices=MESSAGE_TYPES,
        default='text'
    )


    is_edited = models.BooleanField(
        default=False
    )


    is_deleted = models.BooleanField(
        default=False
    )


    created_at = models.DateTimeField(
        auto_now_add=True
    )


    updated_at = models.DateTimeField(
        auto_now=True
    )


    def __str__(self):
        return f'{self.sender.username}: {self.content[:20]}'