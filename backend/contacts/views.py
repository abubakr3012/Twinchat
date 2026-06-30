from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Contact
from .serializers import ContactSerializer, ContactCreateSerializer
from .permissions import IsContactOwner


class ContactListCreateView(generics.ListCreateAPIView):
   
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Contact.objects.filter(
            owner=self.request.user,
            is_blocked=False
        ).select_related('contact')

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ContactCreateSerializer
        return ContactSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context


class ContactDetailView(generics.RetrieveUpdateDestroyAPIView):
    
    permission_classes = [IsAuthenticated, IsContactOwner]
    serializer_class = ContactSerializer

    def get_queryset(self):
        return Contact.objects.filter(
            owner=self.request.user
        ).select_related('contact')

    def partial_update(self, request, *args, **kwargs):
        kwargs['partial'] = True
        return self.update(request, *args, **kwargs)


class BlockContactView(APIView):
    
    permission_classes = [IsAuthenticated, IsContactOwner]

    def get_object(self, pk):
        try:
            contact = Contact.objects.get(pk=pk, owner=self.request.user)
            self.check_object_permissions(self.request, contact)
            return contact
        except Contact.DoesNotExist:
            return None

    def post(self, request, pk, action):
        contact = self.get_object(pk)
        if not contact:
            return Response(
                {'detail': 'Контакт не найден.'},
                status=status.HTTP_404_NOT_FOUND
            )

        if action == 'block':
            contact.is_blocked = True
            contact.save()
            return Response({'detail': 'Пользователь заблокирован.'})

        elif action == 'unblock':
            contact.is_blocked = False
            contact.save()
            return Response({'detail': 'Пользователь разблокирован.'})

        return Response(
            {'detail': 'Неизвестное действие.'},
            status=status.HTTP_400_BAD_REQUEST
        )


class BlockedContactListView(generics.ListAPIView):
    
    permission_classes = [IsAuthenticated]
    serializer_class = ContactSerializer

    def get_queryset(self):
        return Contact.objects.filter(
            owner=self.request.user,
            is_blocked=True
        ).select_related('contact')