from rest_framework import serializers
from .models import Contact


class ContactSerializer(serializers.ModelSerializer):

    contact_username = serializers.CharField(
        source='contact.username',
        read_only=True
    )

    contact_id = serializers.IntegerField(
        source='contact.id',
        read_only=True
    )

    class Meta:
        model = Contact
        fields = [
            'id',
            'contact_id',
            'contact_username',
            'nickname',
            'is_blocked',
            'added_at',
        ]
        read_only_fields = ['id', 'added_at']


class ContactCreateSerializer(serializers.ModelSerializer):

    class Meta:
        model = Contact
        fields = [
            'contact',
            'nickname',
        ]

    def validate_contact(self, value):
        request = self.context['request']
        if value == request.user:
            raise serializers.ValidationError("Нельзя добавить себя в контакты.")
        return value

    def validate(self, attrs):
        request = self.context['request']
        if Contact.objects.filter(owner=request.user, contact=attrs['contact']).exists():
            raise serializers.ValidationError("Этот пользователь уже в ваших контактах.")
        return attrs

    def create(self, validated_data):
        validated_data['owner'] = self.context['request'].user
        return super().create(validated_data)