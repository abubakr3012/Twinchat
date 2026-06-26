from django.utils import timezone
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Story, StoryView
from .serializers import StorySerializer, StoryCreateSerializer, StoryViewSerializer
from .permissions import IsStoryOwner


class StoryListCreateView(generics.ListCreateAPIView):
    
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Story.objects.filter(
            expires_at__gt=timezone.now()
        ).select_related('user').order_by('-created_at')

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return StoryCreateSerializer
        return StorySerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context


class MyStoriesView(generics.ListAPIView):
    
    permission_classes = [IsAuthenticated]
    serializer_class = StorySerializer

    def get_queryset(self):
        return Story.objects.filter(
            user=self.request.user
        ).order_by('-created_at')


class StoryDetailView(generics.RetrieveDestroyAPIView):
    
    permission_classes = [IsAuthenticated, IsStoryOwner]
    serializer_class = StorySerializer
    queryset = Story.objects.all()

    def retrieve(self, request, *args, **kwargs):
        story = self.get_object()
        if story.user != request.user:
            StoryView.objects.get_or_create(
                story=story,
                viewer=request.user
            )
        serializer = self.get_serializer(story)
        return Response(serializer.data)


class StoryViewersView(generics.ListAPIView):
   
    permission_classes = [IsAuthenticated]
    serializer_class = StoryViewSerializer

    def get_queryset(self):
        story_id = self.kwargs['pk']
        return StoryView.objects.filter(
            story_id=story_id,
            story__user=self.request.user
        ).select_related('viewer')