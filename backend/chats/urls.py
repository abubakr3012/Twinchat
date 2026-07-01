from django.urls import path

from .views import (
    ChatListCreateView,
    ChatDetailView,
    ChatMemberAddView
)

urlpatterns = [

    path(
        '',
        ChatListCreateView.as_view()
    ),

    path(
        '<int:pk>/',
        ChatDetailView.as_view()
    ),

    path(
        '<int:pk>/members/',
        ChatMemberAddView.as_view()
    ),
]