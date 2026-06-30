from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from .models import Reaction
from .serializers import ReactionSerializer, ReactionCreateSerializer
from .permissions import IsReactionOwner


class ReactionListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        message_id = self.request.query_params.get('message')
        if message_id:
            return Reaction.objects.filter(
                message_id=message_id
            ).select_related('user')
        return Reaction.objects.none()

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ReactionCreateSerializer
        return ReactionSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context


class ReactionDeleteView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated, IsReactionOwner]
    queryset = Reaction.objects.all()
    serializer_class = ReactionSerializer