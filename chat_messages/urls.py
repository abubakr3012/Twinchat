from django.urls import path

from .views import (
    MessageListCreateView,
    MessageUpdateDeleteView
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

]