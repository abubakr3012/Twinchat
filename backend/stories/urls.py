from django.urls import path
from .views import (
    StoryListCreateView,
    MyStoriesView,
    StoryDetailView,
    StoryViewersView,
)

urlpatterns = [
    path('', StoryListCreateView.as_view(), name='story-list-create'),
    path('my/', MyStoriesView.as_view(), name='story-my'),
    path('<int:pk>/', StoryDetailView.as_view(), name='story-detail'),
    path('<int:pk>/viewers/', StoryViewersView.as_view(), name='story-viewers'),
]