from rest_framework import serializers
from .models import Attachment


class AttachmentSerializer(serializers.ModelSerializer):

    class Meta:
        model = Attachment
        fields = [
            'id',
            'message',
            'file',
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


class AttachmentUploadSerializer(serializers.ModelSerializer):

    class Meta:
        model = Attachment
        fields = [
            'message',
            'file',
            'file_type',
        ]

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