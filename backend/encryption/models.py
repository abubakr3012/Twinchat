from django.db import models
from django.conf import settings


class SafeModeSession(models.Model):

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='safe_mode_session'
    )

    encrypted_key = models.TextField()

    key_fingerprint = models.CharField(
        max_length=8
    )

    is_active = models.BooleanField(
        default=False
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    updated_at = models.DateTimeField(
        auto_now=True
    )

    def __str__(self):
        return f'{self.user.username} — safe mode ({"on" if self.is_active else "off"})'


class SafeModeKeyShareLog(models.Model):

    SHARE_METHODS = (
        ('qr', 'QR Code'),
        ('copy', 'Copy'),
        ('link', 'Link'),
        ('nfc', 'NFC'),
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='key_share_logs'
    )

    shared_with = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='received_key_logs'
    )

    method = models.CharField(
        max_length=20,
        choices=SHARE_METHODS
    )

    shared_at = models.DateTimeField(
        auto_now_add=True
    )

    is_revoked = models.BooleanField(
        default=False
    )

    def __str__(self):
        return f'{self.user.username} shared key via {self.method}'


class SafeModeUIState(models.Model):

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='safe_mode_ui'
    )

    key_entered = models.BooleanField(
        default=False
    )

    auto_lock_minutes = models.PositiveIntegerField(
        default=10
    )

    updated_at = models.DateTimeField(
        auto_now=True
    )

    def __str__(self):
        return f'{self.user.username} — UI state'