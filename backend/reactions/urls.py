from django.urls import path
from .views import (
    ReactionListCreateView,
    ReactionDeleteView,
)

urlpatterns = [
    path('', ReactionListCreateView.as_view(), name='reaction-list-create'),
    path('<int:pk>/', ReactionDeleteView.as_view(), name='reaction-delete'),
]