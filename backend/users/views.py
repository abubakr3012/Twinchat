from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from .models import User, PhoneCode
from .serializers import (
    UserSerializer,
    UserUpdateSerializer,
    RegisterSerializer,
    LoginSerializer,
    PhoneCodeRequestSerializer,
    PhoneCodeVerifySerializer,
)
from rest_framework.permissions import AllowAny
from .permissions import IsOwner
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
import random
from django.utils import timezone
from datetime import timedelta

CODE_TTL_MINUTES = 5
CODE_MAX_ATTEMPTS = 5


def _generate_code() -> str:
    """6-значный цифровой код."""
    return f'{random.randint(0, 999999):06d}'


def _send_sms_stub(phone: str, code: str) -> None:
    """
    Заглушка отправки SMS. В продакшне подключить реальный шлюз
    (Twilio, SMS.ru, Eskiz, PlayMobile и т.п.).
    В dev-режиме пишем в логи — этого хватит, чтобы код был виден.
    """
    print(f'[SMS] -> {phone}: ваш код подтверждения {code}')


class RequestPhoneCodeView(APIView):
    """POST /api/users/phone/request-code/ { phone_number } → { sent: true, debug_code?: '...' }"""

    permission_classes = [AllowAny]
    serializer_class = PhoneCodeRequestSerializer

    def post(self, request):
        serializer = self.serializer_class(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data['phone_number']

        # Можно ограничить частоту: не выдавать новый код, если предыдущий ещё жив.
        cooldown = timezone.now() - timedelta(seconds=30)
        last = (
            PhoneCode.objects
            .filter(phone_number=phone, is_used=False, created_at__gte=cooldown)
            .order_by('-created_at')
            .first()
        )
        if last is not None:
            return Response(
                {
                    'detail': 'Код уже отправлен. Подождите 30 секунд, прежде чем запрашивать снова.',
                },
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        code = _generate_code()
        PhoneCode.objects.create(
            phone_number=phone,
            code=code,
            expires_at=timezone.now() + timedelta(minutes=CODE_TTL_MINUTES),
        )
        _send_sms_stub(phone, code)

        payload = {'sent': True, 'phone_number': phone}
        # В DEBUG возвращаем код в ответе, чтобы можно было тестировать без SMS-шлюза.
        from django.conf import settings as dj_settings
        if getattr(dj_settings, 'DEBUG', False):
            payload['debug_code'] = code
        return Response(payload, status=status.HTTP_200_OK)


class VerifyPhoneCodeView(APIView):
    """
    POST /api/users/phone/verify/ { phone_number, code }
    → { access, refresh, user, is_new_user }
    Если пользователя с таким номером нет — создаёт его автоматически.
    """

    permission_classes = [AllowAny]
    serializer_class = PhoneCodeVerifySerializer

    def post(self, request):
        serializer = self.serializer_class(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data['phone_number']
        code = serializer.validated_data['code']

        # Берём последний неиспользованный код по этому номеру.
        phone_code = (
            PhoneCode.objects
            .filter(phone_number=phone, is_used=False)
            .order_by('-created_at')
            .first()
        )
        if phone_code is None:
            return Response(
                {'detail': 'Код не найден. Запросите новый.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if phone_code.is_expired:
            return Response(
                {'detail': 'Срок действия кода истёк. Запросите новый.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if phone_code.attempts >= CODE_MAX_ATTEMPTS:
            return Response(
                {'detail': 'Превышено число попыток. Запросите новый код.'},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        if phone_code.code != code:
            phone_code.attempts = phone_code.attempts + 1
            phone_code.save(update_fields=['attempts'])
            return Response(
                {'detail': 'Неверный код'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Код верный → помечаем использованным.
        phone_code.is_used = True
        phone_code.save(update_fields=['is_used'])

        # Находим или создаём пользователя.
        is_new_user = False
        user = User.objects.filter(phone_number=phone).first()
        if user is None:
            # Генерируем уникальный username и email-плейсхолдер на основе телефона.
            base = 'u_' + phone.lstrip('+')[-10:]
            username = base
            i = 0
            while User.objects.filter(username=username).exists():
                i += 1
                username = f'{base}_{i}'
            user_email = f'{username}@twinchat.local'
            user = User.objects.create(
                username=username,
                phone_number=phone,
                email=user_email,
            )
            user.set_unusable_password()
            user.save(update_fields=['password'])
            is_new_user = True

        phone_code.user = user
        phone_code.save(update_fields=['user'])

        refresh = RefreshToken.for_user(user)
        return Response(
            {
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'is_new_user': is_new_user,
                'user': UserSerializer(user).data,
            },
            status=status.HTTP_200_OK,
        )

class RegisterView(generics.CreateAPIView):

    serializer_class = RegisterSerializer

    permission_classes = [
        AllowAny
    ]


    def create(self, request, *args, **kwargs):

        serializer = self.get_serializer(
            data=request.data
        )

        serializer.is_valid(
            raise_exception=True
        )

        user = serializer.save()


        refresh = RefreshToken.for_user(
            user
        )


        return Response(
            {
                "user": serializer.data,

                "access": str(
                    refresh.access_token
                ),

                "refresh": str(
                    refresh
                )
            },
            status=status.HTTP_201_CREATED
        )



class LoginView(generics.GenericAPIView):

    serializer_class = LoginSerializer

    permission_classes = [
        AllowAny
    ]


    def post(self, request):

        serializer = self.get_serializer(
            data=request.data
        )

        serializer.is_valid(
            raise_exception=True
        )


        user = serializer.validated_data["user"]


        refresh = RefreshToken.for_user(
            user
        )


        return Response(
            {
                "access": str(
                    refresh.access_token
                ),

                "refresh": str(
                    refresh
                )
            }
        )

class CurrentUserView(
    generics.RetrieveUpdateAPIView
):

    permission_classes = [
        IsAuthenticated
    ]

    def get_object(self):

        return self.request.user


    def get_serializer_class(self):

        if self.request.method == "GET":
            return UserSerializer

        return UserUpdateSerializer



class UserDetailView(
    generics.RetrieveAPIView
):

    queryset = User.objects.all()

    serializer_class = UserSerializer

    permission_classes = [
        IsAuthenticated
    ]



class UserSearchView(
    generics.ListAPIView
):

    serializer_class = UserSerializer

    permission_classes = [
        IsAuthenticated
    ]


    def get_queryset(self):

        query = self.request.query_params.get(
            'q'
        )

        if query:
            return User.objects.filter(
                username__icontains=query
            )

        return User.objects.none()