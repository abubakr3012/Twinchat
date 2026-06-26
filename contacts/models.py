from django.db import models
from django.conf import settings


class Contact(models.Model):

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='contacts'
    )

    contact = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='contact_of'
    )

    nickname = models.CharField(
        max_length=100,
        null=True,
        blank=True
    )

    is_blocked = models.BooleanField(
        default=False
    )

    added_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        unique_together = ('owner', 'contact')

    def __str__(self):
        return f"{self.owner.username} -> {self.contact.username}"