import os
import subprocess
import sys
import time


PROJECT_NAME = "twinchat"

GUNICORN_NAME = "twinchat-engine"
NGINX_NAME = "twinchat-gateway"

BASE_DIR = "/var/www/twinchat"


class DeployError(Exception):
    """Кастомное исключение для ошибок деплоя."""
    pass


def execute(command):

    print("\n")
    print("=" * 60)
    print(command)
    print("=" * 60)

    try:
        subprocess.run(
            command,
            shell=True,
            check=True,
        )

    except subprocess.CalledProcessError as e:
        raise DeployError(
            f"Команда завершилась с ошибкой (код {e.returncode}): {command}"
        ) from e

    except FileNotFoundError as e:
        raise DeployError(
            f"Команда/интерпретатор не найден: {command}"
        ) from e


def banner():

    print(
        """
=================================

        TWINCHAT DEPLOYER

        Engine:
        twinchat-engine

        Gateway:
        twinchat-gateway

=================================
"""
    )


def install_packages():

    execute("apt update")

    execute(
        """
apt install -y \
docker.io \
docker-compose \
nginx \
python3-pip \
python3-venv \
certbot \
python3-certbot-nginx
"""
    )


def create_directories():

    try:
        os.makedirs(BASE_DIR, exist_ok=True)
        os.makedirs("/etc/systemd/system", exist_ok=True)
        os.makedirs("/etc/nginx/sites-available", exist_ok=True)

    except OSError as e:
        raise DeployError(f"Не удалось создать директории: {e}") from e


def start_docker():

    print("Starting TwinChat containers...")

    execute("docker compose down")
    execute("docker compose up -d --build")


def django_prepare():

    print("Preparing Django...")

    time.sleep(15)

    execute(
        """
docker exec twinchat-backend \
python manage.py makemigrations
"""
    )

    execute(
        """
docker exec twinchat-backend \
python manage.py migrate
"""
    )

    execute(
        """
docker exec twinchat-backend \
python manage.py collectstatic --noinput
"""
    )


def create_gunicorn_service():

    service = f"""
[Unit]
Description={GUNICORN_NAME}
After=network.target

[Service]
User=root
WorkingDirectory={BASE_DIR}
ExecStart={BASE_DIR}/venv/bin/gunicorn \
config.wsgi:application \
--name {GUNICORN_NAME} \
--workers 4 \
--bind unix:/run/{GUNICORN_NAME}.sock

Restart=always

[Install]
WantedBy=multi-user.target
"""

    try:
        with open("/etc/systemd/system/twinchat.service", "w") as file:
            file.write(service)

    except OSError as e:
        raise DeployError(
            f"Не удалось записать systemd unit-файл: {e}"
        ) from e

    execute("systemctl daemon-reload")
    execute("systemctl enable twinchat")


def create_nginx():

    nginx = f"""
server {{
    listen 80;
    server_name _;

    location / {{
        proxy_pass http://unix:/run/{GUNICORN_NAME}.sock;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }}

    location /static/ {{
        alias {BASE_DIR}/static/;
    }}
}}
"""

    path = f"/etc/nginx/sites-available/{NGINX_NAME}.conf"

    try:
        with open(path, "w") as file:
            file.write(nginx)

    except OSError as e:
        raise DeployError(
            f"Не удалось записать конфиг nginx: {e}"
        ) from e

    execute(
        f"ln -sf {path} /etc/nginx/sites-enabled/{NGINX_NAME}.conf"
    )

    execute("nginx -t")
    execute("systemctl restart nginx")


def start_services():

    execute("systemctl restart twinchat")
    execute("systemctl restart nginx")


def deploy():

    banner()

    steps = [
        ("Установка пакетов", install_packages),
        ("Создание директорий", create_directories),
        ("Запуск Docker-контейнеров", start_docker),
        ("Подготовка Django", django_prepare),
        ("Создание systemd-сервиса Gunicorn", create_gunicorn_service),
        ("Создание конфигурации Nginx", create_nginx),
        ("Запуск сервисов", start_services),
    ]

    for step_name, step_func in steps:
        try:
            step_func()

        except DeployError as e:
            print(f"\nОШИБКА на шаге «{step_name}»: {e}")
            sys.exit(1)

        except Exception as e:
            print(
                f"\nНЕОЖИДАННАЯ ОШИБКА на шаге «{step_name}»: {e}"
            )
            sys.exit(1)

    print(
        """

=================================

 TwinChat успешно запущен 🚀

 Gunicorn:
 twinchat-engine

 Nginx:
 twinchat-gateway

 Docker:
 twinchat containers

=================================

"""
    )


if __name__ == "__main__":

    try:
        deploy()

    except KeyboardInterrupt:
        print("\nДеплой прерван пользователем.")
        sys.exit(130)