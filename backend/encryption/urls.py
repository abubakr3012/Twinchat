from django.urls import path
from .views import (
    SafeModeStatusView,
    SafeModeEnableView,
    SafeModeKeyShareListCreateView,
    SafeModeRevokeView,
    SafeModeUIStateView,
)

urlpatterns = [
    path('status/', SafeModeStatusView.as_view(), name='safe-mode-status'),
    path('<str:action>/', SafeModeEnableView.as_view(), name='safe-mode-action'),
    path('shares/', SafeModeKeyShareListCreateView.as_view(), name='safe-mode-shares'),
    path('shares/<int:pk>/revoke/', SafeModeRevokeView.as_view(), name='safe-mode-revoke'),
    path('ui/', SafeModeUIStateView.as_view(), name='safe-mode-ui'),
]