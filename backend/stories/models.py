from django.db import models
from django.conf import settings
from django.utils import timezone
import datetime


class Story(models.Model):

    MEDIA_TYPES = (
        ('image', 'Image'),
        ('video', 'Video'),
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='stories'
    )

    media = models.FileField(
        upload_to='media/stories/'
    )

    media_type = models.CharField(
        max_length=20,
        choices=MEDIA_TYPES
    )

    caption = models.TextField(
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    expires_at = models.DateTimeField(
        null=True,
        blank=True
    )

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + datetime.timedelta(hours=24)
        super().save(*args, **kwargs)

    def is_expired(self):
        return timezone.now() > self.expires_at

    def __str__(self):
        return f'{self.user.username} — story {self.id}'


class StoryView(models.Model):

    story = models.ForeignKey(
        Story,
        on_delete=models.CASCADE,
        related_name='views'
    )

    viewer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='viewed_stories'
    )

    viewed_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        unique_together = ('story', 'viewer')

    def __str__(self):
        return f'{self.viewer.username} viewed story {self.story.id}'