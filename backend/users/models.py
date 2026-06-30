from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):

    email = models.EmailField(
        unique=True
    )

    avatar = models.ImageField(
        upload_to='avatars/',
        null=True,
        blank=True
    )

    bio = models.TextField(
        max_length=500,
        blank=True,
        null=True
    )

    phone_number = models.CharField(
        max_length=20,
        unique=True,
        null=True,
        blank=True
    )

    last_seen = models.DateTimeField(
        null=True,
        blank=True
    )

    is_online = models.BooleanField(
        default=False
    )

    public_key = models.TextField(
        null=True,
        blank=True
    )

    key_fingerprint = models.CharField(
        max_length=100,
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
        return self.username



class Profile(models.Model):

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='profile'
    )

    nickname = models.CharField(
        max_length=20,
        unique=True,
        null=True,
        blank=True
    )

    photo = models.ImageField(
        upload_to='profile_photo/',
        blank=True,
        null=True
    )

    bio = models.CharField(
        max_length=150,
        null=True,
        blank=True
    )

    birthday = models.DateField(
        null=True,
        blank=True
    )


    def __str__(self):
        return f'{self.user.username} profile'


class PhoneCode(models.Model):
    """Одноразовый SMS-код для входа/регистрации по номеру телефона."""

    phone_number = models.CharField(max_length=20, db_index=True)
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    attempts = models.PositiveSmallIntegerField(default=0)
    # Если код успешно использован — какой пользователь залогинился.
    user = models.ForeignKey(
        'User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='phone_codes',
    )

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['phone_number', 'is_used', '-created_at']),
        ]

    def __str__(self):
        return f'{self.phone_number} → {self.code} (used={self.is_used})'

    @property
    def is_expired(self):
        from django.utils import timezone
        return timezone.now() >= self.expires_at