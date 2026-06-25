from django.urls import path

from .views import (
    CurrentUserView,
    UserDetailView,
    UserSearchView,
    RegisterView,
    LoginView

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
        RegisterView.as_view()
    ),


    path(
        'login/',
        LoginView.as_view()
    ),

]