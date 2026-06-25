from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from .models import User
from .serializers import (
    UserSerializer,
    UserUpdateSerializer,
    RegisterSerializer,
    LoginSerializer
)
from rest_framework.permissions import AllowAny
from .permissions import IsOwner
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

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