from django.urls import path
from .views import (
    ContactListCreateView,
    ContactDetailView,
    BlockContactView,
    BlockedContactListView,
)

urlpatterns = [
    path('', ContactListCreateView.as_view(), name='contact-list-create'),
    path('blocked/', BlockedContactListView.as_view(), name='contact-blocked-list'),
    path('<int:pk>/', ContactDetailView.as_view(), name='contact-detail'),
    path('<int:pk>/<str:action>/', BlockContactView.as_view(), name='contact-block-action'),
]