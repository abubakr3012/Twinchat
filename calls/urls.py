from django.urls import path
from .views import (
    CallListCreateView,
    CallDetailView,
    CallActionView,
)

urlpatterns = [
    path('', CallListCreateView.as_view(), name='call-list-create'),
    path('<int:pk>/', CallDetailView.as_view(), name='call-detail'),
    path('<int:pk>/<str:action>/', CallActionView.as_view(), name='call-action'),
]