from rest_framework import serializers
from .models import Message

class MessageSerializer(serializers.ModelSerializer):

    sender_username = serializers.CharField(
        source='sender.username',
        read_only=True
    )


    class Meta:

        model = Message

        fields = [
            'id',
            'chat',
            'sender',
            'sender_username',
            'content',
            'message_type',
            'is_edited',
            'is_deleted',
            'created_at',
            'updated_at'
        ]


        read_only_fields = [
            'chat',
            'sender',
            'created_at',
            'updated_at'
        ]