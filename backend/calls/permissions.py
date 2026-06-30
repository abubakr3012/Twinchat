from rest_framework.permissions import BasePermission


class IsCallInitiator(BasePermission):
    def has_object_permission(self, request, view, obj):
        return obj.initiator == request.user