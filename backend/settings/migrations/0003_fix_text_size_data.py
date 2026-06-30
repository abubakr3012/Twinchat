from django.db import migrations


def fix_text_size(apps, schema_editor):
    ChatSettings = apps.get_model('settings', 'ChatSettings')
    mapping = {'small': 12, 'medium': 14, 'large': 18}
    for obj in ChatSettings.objects.all():
        if isinstance(obj.text_size, str):
            obj.text_size = mapping.get(obj.text_size, 14)
            obj.save(update_fields=['text_size'])


class Migration(migrations.Migration):

    dependencies = [
        ('settings', '0002_alter_chatsettings_text_size'),
    ]

    operations = [
        migrations.RunPython(fix_text_size),
    ]
