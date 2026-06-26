from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Attachment
from .serializers import AttachmentSerializer, AttachmentUploadSerializer
from .permissions import IsMessageSender


class AttachmentUploadView(generics.CreateAPIView):
    
    permission_classes = [IsAuthenticated]
    serializer_class = AttachmentUploadSerializer


class AttachmentListView(generics.ListAPIView):
    
    permission_classes = [IsAuthenticated]
    serializer_class = AttachmentSerializer

    def get_queryset(self):
        message_id = self.request.query_params.get('message')
        if message_id:
            return Attachment.objects.filter(message_id=message_id)
        return Attachment.objects.none()


class AttachmentDetailView(generics.RetrieveDestroyAPIView):
    
    permission_classes = [IsAuthenticated, IsMessageSender]
    serializer_class = AttachmentSerializer
    queryset = Attachment.objects.all()