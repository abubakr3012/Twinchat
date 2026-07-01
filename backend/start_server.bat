@echo off
echo Starting TwinChat WebSocket Server...
set DJANGO_SETTINGS_MODULE=config.settings
python -m daphne -b 0.0.0.0 -p 8000 config.asgi:application
pause
