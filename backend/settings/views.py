from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from .models import ChatSettings, Privacy, AppLanguage
from .serializers import ChatSettingsSerializer, PrivacySerializer, AppLanguageSerializer


class ChatSettingsView(generics.RetrieveUpdateAPIView):
    
    permission_classes = [IsAuthenticated]
    serializer_class = ChatSettingsSerializer

    def get_object(self):
        obj, _ = ChatSettings.objects.get_or_create(user=self.request.user)
        return obj


class PrivacyView(generics.RetrieveUpdateAPIView):
    
    permission_classes = [IsAuthenticated]
    serializer_class = PrivacySerializer

    def get_object(self):
        obj, _ = Privacy.objects.get_or_create(user=self.request.user)
        return obj


class AppLanguageView(generics.RetrieveUpdateAPIView):
    
    permission_classes = [IsAuthenticated]
    serializer_class = AppLanguageSerializer

    def get_object(self):
        obj, _ = AppLanguage.objects.get_or_create(user=self.request.user)
        return obj