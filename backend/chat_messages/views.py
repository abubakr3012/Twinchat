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
        ).order_by('-created_at')


    def perform_create(
        self,
        serializer
    ):

        serializer.save(
            sender=self.request.user,
            chat_id=self.kwargs['chat_id']
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

    def perform_update(self, serializer):
        serializer.save()
        # Mark message as read by current user
        self.object.read_by.add(self.request.user)


class MessageMarkReadView(generics.UpdateAPIView):
    
    permission_classes = [IsAuthenticated]
    serializer_class = MessageSerializer
    
    def get_queryset(self):
        return Message.objects.filter(chat_id=self.kwargs['chat_id'])
    
    def get_object(self):
        message_id = self.kwargs['message_id']
        return Message.objects.get(id=message_id)
    
    def perform_update(self, serializer):
        serializer.save()
        self.object.read_by.add(self.request.user)