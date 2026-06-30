from django.utils import timezone
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Call, CallParticipant
from .serializers import CallSerializer, CallCreateSerializer
from .permissions import IsCallInitiator


class CallListCreateView(generics.ListCreateAPIView):
    
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Call.objects.filter(
            participants__user=self.request.user
        ).select_related('initiator', 'chat').order_by('-created_at')

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return CallCreateSerializer
        return CallSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def perform_create(self, serializer):
        call = serializer.save()
        CallParticipant.objects.create(
            call=call,
            user=self.request.user,
            joined_at=timezone.now()
        )


class CallDetailView(generics.RetrieveAPIView):
    
    permission_classes = [IsAuthenticated]
    serializer_class = CallSerializer
    queryset = Call.objects.all()


class CallActionView(APIView):
    
    permission_classes = [IsAuthenticated]

    def get_object(self, pk):
        try:
            return Call.objects.get(pk=pk)
        except Call.DoesNotExist:
            return None

    def post(self, request, pk, action):
        call = self.get_object(pk)
        if not call:
            return Response(
                {'detail': 'Звонок не найден.'},
                status=status.HTTP_404_NOT_FOUND
            )

        if action == 'accept':
            call.status = 'active'
            call.started_at = timezone.now()
            call.save()
            CallParticipant.objects.get_or_create(
                call=call,
                user=request.user,
                defaults={'joined_at': timezone.now()}
            )
            return Response({'detail': 'Звонок принят.'})

        elif action == 'reject':
            call.status = 'rejected'
            call.save()
            return Response({'detail': 'Звонок отклонён.'})

        elif action == 'end':
            call.status = 'ended'
            call.ended_at = timezone.now()
            call.save()
            return Response({'detail': 'Звонок завершён.'})

        elif action == 'leave':
            participant = CallParticipant.objects.filter(
                call=call,
                user=request.user
            ).first()
            if participant:
                participant.left_at = timezone.now()
                participant.save()
            return Response({'detail': 'Вы вышли из звонка.'})

        return Response(
            {'detail': 'Неизвестное действие.'},
            status=status.HTTP_400_BAD_REQUEST
        )