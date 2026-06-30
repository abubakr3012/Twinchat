from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from .models import Message
from .serializers import MessageSerializer
from .permissions import IsMessageOwner



class MessageListCreateView(
    generics.ListCreateAPIView
):

    serializer_class = MessageSerializer

    permission_classes = [
        IsAuthenticated
    ]


    def get_queryset(self):

        chat_id = self.kwargs['chat_id']

        return Message.objects.filter(
            chat_id=chat_id
        )


    def perform_create(
        self,
        serializer
    ):

        serializer.save(
            sender=self.request.user
        )



class MessageUpdateDeleteView(
    generics.RetrieveUpdateDestroyAPIView
):

    queryset = Message.objects.all()

    serializer_class = MessageSerializer

    permission_classes = [
        IsAuthenticated,
        IsMessageOwner
    ]