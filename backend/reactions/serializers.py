from rest_framework import serializers
from .models import Reaction


class ReactionSerializer(serializers.ModelSerializer):

    username = serializers.CharField(
        source='user.username',
        read_only=True
    )

    class Meta:
        model = Reaction
        fields = [
            'id',
            'message',
            'user',
            'username',
            'emoji',
            'created_at',
        ]
        read_only_fields = ['id', 'user', 'created_at']


class ReactionCreateSerializer(serializers.ModelSerializer):

    class Meta:
        model = Reaction
        fields = [
            'message',
            'emoji',
        ]

    def validate(self, attrs):
        request = self.context['request']
        if Reaction.objects.filter(
            message=attrs['message'],
            user=request.user,
            emoji=attrs['emoji']
        ).exists():
            raise serializers.ValidationError('Вы уже поставили эту реакцию.')
        return attrs

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)