from django.urls import path
from .views import (
    AttachmentUploadView,
    AttachmentListView,
    AttachmentDetailView,
)

urlpatterns = [
    path('', AttachmentListView.as_view(), name='attachment-list'),
    path('upload/', AttachmentUploadView.as_view(), name='attachment-upload'),
    path('<int:pk>/', AttachmentDetailView.as_view(), name='attachment-detail'),
]