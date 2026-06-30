from django.db import models
from django.conf import settings


class ChatSettings(models.Model):

    THEME_CHOICES = (
        ('light', 'Light'),
        ('dark', 'Dark'),
        ('system', 'System'),
    )

    TEXT_SIZE_CHOICES = (
        ('small', 'Small'),
        ('medium', 'Medium'),
        ('large', 'Large'),
    )

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='chat_settings'
    )

    theme = models.CharField(
        max_length=20,
        choices=THEME_CHOICES,
        default='system'
    )

    text_size = models.CharField(
        max_length=20,
        choices=TEXT_SIZE_CHOICES,
        default='medium'
    )

    notifications = models.BooleanField(
        default=True
    )

    def __str__(self):
        return f'{self.user.username} — settings'


class Privacy(models.Model):

    VISIBILITY_CHOICES = (
        ('everyone', 'Everyone'),
        ('contacts', 'Contacts'),
        ('nobody', 'Nobody'),
    )

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='privacy'
    )

    see_phone_number = models.CharField(
        max_length=20,
        choices=VISIBILITY_CHOICES,
        default='contacts'
    )

    see_profile_photo = models.CharField(
        max_length=20,
        choices=VISIBILITY_CHOICES,
        default='everyone'
    )

    see_last_seen = models.CharField(
        max_length=20,
        choices=VISIBILITY_CHOICES,
        default='everyone'
    )

    auto_delete_messages = models.BooleanField(
        default=False
    )

    message_ttl_days = models.PositiveIntegerField(
        null=True,
        blank=True,
        help_text='Автоудаление сообщений через N дней'
    )

    two_factor_auth = models.BooleanField(
        default=False
    )

    def __str__(self):
        return f'{self.user.username} — privacy'


class AppLanguage(models.Model):

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='app_language'
    )

    language = models.CharField(
        max_length=10,
        default='ru'
    )

    auto_translate = models.BooleanField(
        default=False
    )

    def __str__(self):
        return f'{self.user.username} — language: {self.language}'