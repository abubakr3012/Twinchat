from rest_framework.permissions import BasePermission


class IsContactOwner(BasePermission):

    def has_object_permission(self, request, view, obj):
        return obj.owner == request.user