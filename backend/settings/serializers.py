from rest_framework import serializers
from .models import ChatSettings, Privacy, AppLanguage


class ChatSettingsSerializer(serializers.ModelSerializer):

    class Meta:
        model = ChatSettings
        fields = [
            'id',
            'theme',
            'text_size',
            'notifications',
        ]
        read_only_fields = ['id']


class PrivacySerializer(serializers.ModelSerializer):

    class Meta:
        model = Privacy
        fields = [
            'id',
            'see_phone_number',
            'see_profile_photo',
            'see_last_seen',
            'auto_delete_messages',
            'message_ttl_days',
            'two_factor_auth',
        ]
        read_only_fields = ['id']


class AppLanguageSerializer(serializers.ModelSerializer):

    class Meta:
        model = AppLanguage
        fields = [
            'id',
            'language',
            'auto_translate',
        ]
        read_only_fields = ['id']