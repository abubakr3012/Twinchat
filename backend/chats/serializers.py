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

    class Meta:
        model = Chat
        fields = [
            'id',
            'type',
            'name',
            'avatar',
            'members',
            'created_at'
        ]