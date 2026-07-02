from rest_framework import serializers
from .models import Chat, ChatMember


class ChatMemberSerializer(serializers.ModelSerializer):

    username = serializers.CharField(
        source='user.username',
        read_only=True
    )

    class Meta:
        model = ChatMember
        fields = [
            'id',
            'user',
            'username',
            'is_admin',
            'joined_at'
        ]


class ChatSerializer(serializers.ModelSerializer):

    members = ChatMemberSerializer(
        many=True,
        read_only=True
    )

    last_message = serializers.SerializerMethodField()

    class Meta:
        model = Chat
        fields = [
            'id',
            'type',
            'name',
            'avatar',
            'members',
            'last_message',
            'created_at'
        ]

    def get_last_message(self, obj):
        msg = obj.messages.order_by('-created_at').first()
        if msg:
            return {
                'id': msg.id,
                'content': msg.content,
                'message_type': msg.message_type,
                'sender_id': msg.sender_id,
                'sender_username': msg.sender.username,
                'created_at': msg.created_at.isoformat()
            }
        return None