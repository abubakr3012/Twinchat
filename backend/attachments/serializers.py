from rest_framework import serializers
from django.conf import settings
from .models import Attachment


class AttachmentSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = Attachment
        fields = [
            'id',
            'message',
            'file',
            'file_url',
            'file_type',
            'file_name',
            'file_size',
            'duration',
            'width',
            'height',
            'thumbnail',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at']

    def get_file_url(self, obj):
        if obj.file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.file.url)
            return f"{settings.MEDIA_URL}{obj.file}"
        return None


class AttachmentUploadSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = Attachment
        fields = [
            'id',
            'file',
            'file_url',
            'file_type',
            'file_name',
            'file_size',
        ]
        read_only_fields = ['id', 'file_name', 'file_size', 'file_type']

    def get_file_url(self, obj):
        if obj.file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.file.url)
            return f"{settings.MEDIA_URL}{obj.file}"
        return None

    def validate_file(self, value):
        max_size = 100 * 1024 * 1024  # 100 MB
        if value.size > max_size:
            raise serializers.ValidationError('Файл слишком большой. Максимум 100 MB.')
        return value

    def create(self, validated_data):
        file = validated_data['file']
        validated_data['file_name'] = file.name
        validated_data['file_size'] = file.size
        return super().create(validated_data)