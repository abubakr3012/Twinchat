from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
import mimetypes

from .models import Attachment
from .serializers import AttachmentSerializer, AttachmentUploadSerializer
from .permissions import IsMessageSender


class AttachmentUploadView(generics.CreateAPIView):
    
    permission_classes = [IsAuthenticated]
    serializer_class = AttachmentUploadSerializer

    def perform_create(self, serializer):
        file = self.request.FILES.get('file')
        if file:
            mime_type, _ = mimetypes.guess_type(file.name)
            file_type = 'file'
            if mime_type:
                if mime_type.startswith('image'):
                    file_type = 'image'
                elif mime_type.startswith('video'):
                    file_type = 'video'
                elif mime_type.startswith('audio'):
                    file_type = 'audio'
            serializer.save(file_type=file_type)


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