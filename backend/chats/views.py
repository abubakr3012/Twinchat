from rest_framework import generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.contrib.auth import get_user_model

from .models import Chat, ChatMember
from .serializers import ChatSerializer
from .permissions import IsChatMember

User = get_user_model()


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


class ChatDetailView(generics.RetrieveUpdateAPIView):

    queryset = Chat.objects.all()
    serializer_class = ChatSerializer
    permission_classes = [IsAuthenticated, IsChatMember]


class ChatMemberAddView(APIView):
    permission_classes = [IsAuthenticated, IsChatMember]

    def post(self, request, pk):
        chat = get_object_or_404(Chat, pk=pk)
        self.check_object_permissions(request, chat)
        
        user_id = request.data.get('user_id')
        if not user_id:
            return Response({'error': 'user_id is required'}, status=status.HTTP_400_BAD_REQUEST)
            
        user = get_object_or_404(User, pk=user_id)
        
        # Add user to chat
        ChatMember.objects.get_or_create(
            chat=chat,
            user=user,
            defaults={'is_admin': False}
        )
        
        serializer = ChatSerializer(chat)
        return Response(serializer.data, status=status.HTTP_201_CREATED)