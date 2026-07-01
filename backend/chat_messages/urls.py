from django.urls import path

from .views import (
    MessageListCreateView,
    MessageUpdateDeleteView,
    MessageMarkReadView
)



urlpatterns = [

    path(
        'chat/<int:chat_id>/',
        MessageListCreateView.as_view()
    ),


    path(
        '<int:pk>/',
        MessageUpdateDeleteView.as_view()
    ),

    path(
        'chat/<int:chat_id>/<int:message_id>/read/',
        MessageMarkReadView.as_view()
    ),

]