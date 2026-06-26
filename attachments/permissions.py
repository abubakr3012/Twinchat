from rest_framework.permissions import BasePermission


class IsMessageSender(BasePermission):
    def has_object_permission(self, request, view, obj):
        return obj.message.sender == request.user