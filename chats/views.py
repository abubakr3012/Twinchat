from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from .models import Chat,ChatMember
from .serializers import ChatSerializer
from .permissions import IsChatMember


class ChatListCreateView(generics.ListCreateAPIView):

    serializer_class = ChatSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Chat.objects.filter(
            members__user=self.request.user
        ).distinct()

    def perform_create(self, serializer):
        chat = serializer.save()

        ChatMember.objects.create(
            chat=chat,
            user=self.request.user,
            is_admin=True
        )


class ChatDetailView(generics.RetrieveAPIView):

    queryset = Chat.objects.all()
    serializer_class = ChatSerializer
    permission_classes = [IsAuthenticated, IsChatMember]