from .models import User, Profile, PhoneCode
from rest_framework import serializers
from django.contrib.auth import authenticate
import re

class ProfileSerializer(serializers.ModelSerializer):

    class Meta:
        model = Profile
        fields = [
            'nickname',
            'photo',
            'bio',
            'birthday'
        ]



class UserSerializer(serializers.ModelSerializer):

    profile = ProfileSerializer(read_only=True)

    class Meta:
        model = User

        fields = [
            'id',
            'username',
            'email',
            'phone_number',
            'avatar',
            'bio',
            'last_seen',
            'is_online',
            'profile',
            'created_at'
        ]

        read_only_fields = [
            'id',
            'created_at',
            'last_seen',
            'is_online'
        ]



class UserUpdateSerializer(serializers.ModelSerializer):

    class Meta:
        model = User

        fields = [
            'username',
            'email',
            'phone_number',
            'avatar',
            'bio'
        ]

class RegisterSerializer(serializers.ModelSerializer):

    password = serializers.CharField(
        write_only=True
    )


    class Meta:
        model = User

        fields = [
            'username',
            'email',
            'phone_number',
            'password'
        ]


    def create(self, validated_data):

        user = User.objects.create_user(
            **validated_data
        )

        return user



class LoginSerializer(serializers.Serializer):

    username = serializers.CharField()

    password = serializers.CharField(
        write_only=True
    )


    def validate(self, data):

        user = authenticate(
            username=data['username'],
            password=data['password']
        )


        if user is None:
            raise serializers.ValidationError(
                "Неверный логин или пароль"
            )


        data['user'] = user

        return data


_PHONE_RE = re.compile(r'^\+?[0-9]{7,20}$')


def _normalize_phone(value: str) -> str:
    """Нормализация номера: только цифры и один ведущий '+'."""
    if value is None:
        return ''
    digits = re.sub(r'[^0-9+]', '', value.strip())
    if digits.startswith('+'):
        return '+' + re.sub(r'[^0-9]', '', digits[1:])
    return re.sub(r'[^0-9]', '', digits)


class PhoneCodeRequestSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=32)

    def validate_phone_number(self, value):
        phone = _normalize_phone(value)
        if not _PHONE_RE.match(phone):
            raise serializers.ValidationError(
                'Введите корректный номер телефона (от 7 цифр, можно с +)'
            )
        return phone


class PhoneCodeVerifySerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=32)
    code = serializers.CharField(max_length=6, min_length=4)

    def validate(self, data):
        data['phone_number'] = _normalize_phone(data.get('phone_number', ''))
        if not _PHONE_RE.match(data['phone_number']):
            raise serializers.ValidationError(
                {'phone_number': 'Введите корректный номер телефона'}
            )
        if not data['code'].isdigit():
            raise serializers.ValidationError(
                {'code': 'Код должен состоять только из цифр'}
            )
        return data