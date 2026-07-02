from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

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

        message = serializer.save(
            sender=self.request.user,
            chat_id=self.kwargs['chat_id']
        )
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'chat_{message.chat_id}',
            {
                'type': 'chat_message',
                'message_id': message.id,
                'content': message.content,
                'message_type': message.message_type,
                'sender_id': message.sender.id,
                'sender_username': message.sender.username,
                'sent_at': message.created_at.isoformat(),
                'read_by': [u.id for u in message.read_by.all()],
            }
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
        message = serializer.save(is_edited=True)
        # Mark message as read by current user
        message.read_by.add(self.request.user)

        # Broadcast edit
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'chat_{message.chat_id}',
            {
                'type': 'chat_message_edit',
                'message_id': message.id,
                'content': message.content,
            }
        )


class MessageMarkReadView(generics.UpdateAPIView):
    
    permission_classes = [IsAuthenticated]
    serializer_class = MessageSerializer
    
    def get_queryset(self):
        return Message.objects.filter(chat_id=self.kwargs['chat_id'])
    
    def get_object(self):
        message_id = self.kwargs['message_id']
        return Message.objects.get(id=message_id)
    
    def perform_update(self, serializer):
        message = serializer.save()
        message.read_by.add(self.request.user)