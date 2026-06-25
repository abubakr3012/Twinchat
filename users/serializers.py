from .models import User, Profile
from rest_framework import serializers
from django.contrib.auth import authenticate

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