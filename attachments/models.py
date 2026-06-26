from django.db import models


class Attachment(models.Model):

    FILE_TYPES = (
        ('image', 'Image'),
        ('video', 'Video'),
        ('audio', 'Audio'),
        ('file', 'File'),
    )

    message = models.ForeignKey(
        'chat_messages.Message',
        on_delete=models.CASCADE,
        related_name='attachments'
    )

    file = models.FileField(
        upload_to='media/attachments/'
    )

    file_type = models.CharField(
        max_length=20,
        choices=FILE_TYPES
    )

    file_name = models.CharField(
        max_length=255,
        null=True,
        blank=True
    )

    file_size = models.PositiveBigIntegerField(
        null=True,
        blank=True
    )

    duration = models.PositiveIntegerField(
        null=True,
        blank=True,
        help_text='Duration in seconds (for audio/video)'
    )

    width = models.PositiveIntegerField(
        null=True,
        blank=True,
        help_text='Width in pixels (for image/video)'
    )

    height = models.PositiveIntegerField(
        null=True,
        blank=True,
        help_text='Height in pixels (for image/video)'
    )

    thumbnail = models.ImageField(
        upload_to='media/thumbnails/',
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    def __str__(self):
        return f'{self.file_type} — {self.file_name or self.id}'