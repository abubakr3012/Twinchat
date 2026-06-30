from django.urls import path

from .views import (
    CurrentUserView,
    UserDetailView,
    UserSearchView,
    RegisterView,
    LoginView,
    RequestPhoneCodeView,
    VerifyPhoneCodeView,
)


urlpatterns = [

    path(
        'me/',
        CurrentUserView.as_view(),
        name='current-user'
    ),

    path(
        'search/',
        UserSearchView.as_view(),
        name='user-search'
    ),

    path(
        '<int:pk>/',
        UserDetailView.as_view(),
        name='user-detail'
    ),

    path(
        'register/',
        RegisterView.as_view(),
        name='user-register',
    ),

    path(
        'login/',
        LoginView.as_view(),
        name='user-login',
    ),

    # SMS-авторизация по номеру телефона
    path(
        'phone/request-code/',
        RequestPhoneCodeView.as_view(),
        name='phone-request-code',
    ),
    path(
        'phone/verify/',
        VerifyPhoneCodeView.as_view(),
        name='phone-verify',
    ),

]
