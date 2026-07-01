from rest_framework import serializers
from .models import Story, StoryView


class StoryViewSerializer(serializers.ModelSerializer):

    username = serializers.CharField(
        source='viewer.username',
        read_only=True
    )

    class Meta:
        model = StoryView
        fields = [
            'id',
            'viewer',
            'username',
            'viewed_at',
        ]
        read_only_fields = ['id', 'viewer', 'viewed_at']


class StorySerializer(serializers.ModelSerializer):

    username = serializers.CharField(
        source='user.username',
        read_only=True
    )

    views_count = serializers.IntegerField(
        source='views.count',
        read_only=True
    )

    is_expired = serializers.SerializerMethodField()

    # Return absolute URL so the Flutter app can directly use it
    media_url = serializers.SerializerMethodField()

    class Meta:
        model = Story
        fields = [
            'id',
            'user',
            'username',
            'media',
            'media_url',
            'media_type',
            'caption',
            'created_at',
            'expires_at',
            'views_count',
            'is_expired',
        ]
        read_only_fields = ['id', 'user', 'created_at', 'expires_at', 'username', 'views_count', 'is_expired', 'media_url']

    def get_is_expired(self, obj):
        return obj.is_expired()

    def get_media_url(self, obj):
        request = self.context.get('request')
        if obj.media and hasattr(obj.media, 'url'):
            url = obj.media.url
            if request is not None:
                return request.build_absolute_uri(url)
            return url
        return ''


class StoryCreateSerializer(serializers.ModelSerializer):

    class Meta:
        model = Story
        fields = [
            'media',
            'media_type',
            'caption',
        ]

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)