from rest_framework import serializers
from .models import SafeModeSession, SafeModeKeyShareLog, SafeModeUIState


class SafeModeSessionSerializer(serializers.ModelSerializer):

    class Meta:
        model = SafeModeSession
        fields = [
            'id',
            'key_fingerprint',
            'is_active',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'key_fingerprint', 'created_at', 'updated_at']


class SafeModeEnableSerializer(serializers.ModelSerializer):

    encrypted_key = serializers.CharField(write_only=True)
    key_fingerprint = serializers.CharField(write_only=True)

    class Meta:
        model = SafeModeSession
        fields = [
            'encrypted_key',
            'key_fingerprint',
        ]

    def validate_key_fingerprint(self, value):
        if len(value) != 8:
            raise serializers.ValidationError('Fingerprint должен быть 8 символов.')
        return value


class SafeModeKeyShareLogSerializer(serializers.ModelSerializer):

    username = serializers.CharField(
        source='user.username',
        read_only=True
    )

    shared_with_username = serializers.CharField(
        source='shared_with.username',
        read_only=True
    )

    class Meta:
        model = SafeModeKeyShareLog
        fields = [
            'id',
            'user',
            'username',
            'shared_with',
            'shared_with_username',
            'method',
            'shared_at',
            'is_revoked',
        ]
        read_only_fields = ['id', 'user', 'shared_at']


class SafeModeKeyShareCreateSerializer(serializers.ModelSerializer):

    class Meta:
        model = SafeModeKeyShareLog
        fields = [
            'shared_with',
            'method',
        ]

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class SafeModeUIStateSerializer(serializers.ModelSerializer):

    class Meta:
        model = SafeModeUIState
        fields = [
            'id',
            'key_entered',
            'auto_lock_minutes',
            'updated_at',
        ]
        read_only_fields = ['id', 'updated_at']