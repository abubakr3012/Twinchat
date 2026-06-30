import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.utils import timezone

from .models import Message
from chats.models import Chat, ChatMember


class ChatConsumer(AsyncWebsocketConsumer):

    async def connect(self):
        self.chat_id = self.scope['url_route']['kwargs']['chat_id']
        self.room_group_name = f'chat_{self.chat_id}'
        self.user = self.scope['user']

        is_member = await self.check_membership()
        if not is_member:
            await self.close()
            return

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_online',
                'user_id': self.user.id,
                'username': self.user.username,
            }
        )

    async def disconnect(self, close_code):
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_offline',
                'user_id': self.user.id,
                'username': self.user.username,
            }
        )

        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        data = json.loads(text_data)
        event_type = data.get('type')

        if event_type == 'message':
            await self.handle_message(data)

        elif event_type == 'typing':
            await self.handle_typing(data)

        elif event_type == 'read':
            await self.handle_read(data)


    async def handle_message(self, data):
        content = data.get('content', '')
        message_type = data.get('message_type', 'text')

        message = await self.save_message(content, message_type)

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message_id': message.id,
                'content': content,
                'message_type': message_type,
                'sender_id': self.user.id,
                'sender_username': self.user.username,
                'sent_at': message.created_at.isoformat(),
            }
        )

    async def handle_typing(self, data):
        is_typing = data.get('is_typing', False)

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'typing_status',
                'user_id': self.user.id,
                'username': self.user.username,
                'is_typing': is_typing,
            }
        )

    async def handle_read(self, data):
        message_id = data.get('message_id')

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'message_read',
                'message_id': message_id,
                'user_id': self.user.id,
                'username': self.user.username,
            }
        )


    async def chat_message(self, event):
        await self.send(text_data=json.dumps({
            'type': 'message',
            'message_id': event['message_id'],
            'content': event['content'],
            'message_type': event['message_type'],
            'sender_id': event['sender_id'],
            'sender_username': event['sender_username'],
            'sent_at': event['sent_at'],
        }))

    async def typing_status(self, event):
        if event['user_id'] == self.user.id:
            return
        await self.send(text_data=json.dumps({
            'type': 'typing',
            'user_id': event['user_id'],
            'username': event['username'],
            'is_typing': event['is_typing'],
        }))

    async def message_read(self, event):
        await self.send(text_data=json.dumps({
            'type': 'read',
            'message_id': event['message_id'],
            'user_id': event['user_id'],
            'username': event['username'],
        }))

    async def user_online(self, event):
        if event['user_id'] == self.user.id:
            return
        await self.send(text_data=json.dumps({
            'type': 'online',
            'user_id': event['user_id'],
            'username': event['username'],
        }))

    async def user_offline(self, event):
        if event['user_id'] == self.user.id:
            return
        await self.send(text_data=json.dumps({
            'type': 'offline',
            'user_id': event['user_id'],
            'username': event['username'],
        }))


    @database_sync_to_async
    def check_membership(self):
        return ChatMember.objects.filter(
            chat_id=self.chat_id,
            user=self.user
        ).exists()

    @database_sync_to_async
    def save_message(self, content, message_type):
        return Message.objects.create(
            chat_id=self.chat_id,
            sender=self.user,
            content=content,
            message_type=message_type,
        )