from rest_framework import serializers
from .models import Call, CallParticipant


class CallParticipantSerializer(serializers.ModelSerializer):

    username = serializers.CharField(
        source='user.username',
        read_only=True
    )

    class Meta:
        model = CallParticipant
        fields = [
            'id',
            'user',
            'username',
            'joined_at',
            'left_at',
        ]
        read_only_fields = ['id', 'joined_at', 'left_at']


class CallSerializer(serializers.ModelSerializer):

    initiator_username = serializers.CharField(
        source='initiator.username',
        read_only=True
    )

    participants = CallParticipantSerializer(
        many=True,
        read_only=True
    )

    duration_seconds = serializers.SerializerMethodField()

    class Meta:
        model = Call
        fields = [
            'id',
            'chat',
            'initiator',
            'initiator_username',
            'call_type',
            'status',
            'started_at',
            'ended_at',
            'duration_seconds',
            'created_at',
            'participants',
        ]
        read_only_fields = [
            'id',
            'initiator',
            'status',
            'started_at',
            'ended_at',
            'created_at',
        ]

    def get_duration_seconds(self, obj):
        if obj.started_at and obj.ended_at:
            return int((obj.ended_at - obj.started_at).total_seconds())
        return None


class CallCreateSerializer(serializers.ModelSerializer):

    class Meta:
        model = Call
        fields = [
            'chat',
            'call_type',
        ]

    def create(self, validated_data):
        validated_data['initiator'] = self.context['request'].user
        return super().create(validated_data)