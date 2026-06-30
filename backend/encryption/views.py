from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import SafeModeSession, SafeModeKeyShareLog, SafeModeUIState
from .serializers import (
    SafeModeSessionSerializer,
    SafeModeEnableSerializer,
    SafeModeKeyShareLogSerializer,
    SafeModeKeyShareCreateSerializer,
    SafeModeUIStateSerializer,
)
from .permissions import IsKeyShareOwner


class SafeModeStatusView(APIView):
    
    permission_classes = [IsAuthenticated]

    def get(self, request):
        session = SafeModeSession.objects.filter(user=request.user).first()
        if not session:
            return Response({
                'is_active': False,
                'key_fingerprint': None,
            })
        serializer = SafeModeSessionSerializer(session)
        return Response(serializer.data)


class SafeModeEnableView(APIView):
    
    permission_classes = [IsAuthenticated]

    def post(self, request, action):
        if action == 'enable':
            serializer = SafeModeEnableSerializer(data=request.data)
            serializer.is_valid(raise_exception=True)

            session, _ = SafeModeSession.objects.get_or_create(user=request.user)
            session.encrypted_key = serializer.validated_data['encrypted_key']
            session.key_fingerprint = serializer.validated_data['key_fingerprint']
            session.is_active = True
            session.save()

            return Response({
                'detail': 'Safe Mode включён.',
                'key_fingerprint': session.key_fingerprint,
            })

        elif action == 'disable':
            session = SafeModeSession.objects.filter(user=request.user).first()
            if session:
                session.is_active = False
                session.save()
            return Response({'detail': 'Safe Mode выключен.'})

        return Response(
            {'detail': 'Неизвестное действие.'},
            status=status.HTTP_400_BAD_REQUEST
        )


class SafeModeKeyShareListCreateView(generics.ListCreateAPIView):
    
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return SafeModeKeyShareLog.objects.filter(
            user=self.request.user
        ).select_related('shared_with').order_by('-shared_at')

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return SafeModeKeyShareCreateSerializer
        return SafeModeKeyShareLogSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context


class SafeModeRevokeView(APIView):
    
    permission_classes = [IsAuthenticated, IsKeyShareOwner]

    def get_object(self, pk):
        try:
            log = SafeModeKeyShareLog.objects.get(pk=pk)
            self.check_object_permissions(self.request, log)
            return log
        except SafeModeKeyShareLog.DoesNotExist:
            return None

    def post(self, request, pk):
        log = self.get_object(pk)
        if not log:
            return Response(
                {'detail': 'Лог не найден.'},
                status=status.HTTP_404_NOT_FOUND
            )
        log.is_revoked = True
        log.save()
        return Response({'detail': 'Доступ отозван.'})


class SafeModeUIStateView(generics.RetrieveUpdateAPIView):
    
    permission_classes = [IsAuthenticated]
    serializer_class = SafeModeUIStateSerializer

    def get_object(self):
        obj, _ = SafeModeUIState.objects.get_or_create(user=self.request.user)
        return obj