from rest_framework import serializers
from .models import Message

class MessageSerializer(serializers.ModelSerializer):

    sender_username = serializers.CharField(
        source='sender.username',
        read_only=True
    )

    sender_avatar = serializers.URLField(
        source='sender.avatar',
        read_only=True
    )

    read_by = serializers.PrimaryKeyRelatedField(
        many=True,
        read_only=True
    )

    class Meta:

        model = Message

        fields = [
            'id',
            'chat',
            'sender',
            'sender_username',
            'sender_avatar',
            'content',
            'message_type',
            'is_edited',
            'is_deleted',
            'read_by',
            'created_at',
            'updated_at'
        ]


        read_only_fields = [
            'chat',
            'sender',
            'read_by',
            'created_at',
            'updated_at'
        ]