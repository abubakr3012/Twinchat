import os
import subprocess
import time


PROJECT_NAME = "twinchat"

GUNICORN_NAME = "twinchat-engine"
NGINX_NAME = "twinchat-gateway"


BASE_DIR = "/var/www/twinchat"



def execute(command):

    print("\n")
    print("=" * 60)
    print(command)
    print("=" * 60)


    result = subprocess.run(
        command,
        shell=True
    )


    if result.returncode != 0:

        print(
            f"ERROR: {command}"
        )

        exit(1)




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

    execute(
        "apt update"
    )


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

    execute(
        f"mkdir -p {BASE_DIR}"
    )


    execute(
        "mkdir -p /etc/systemd/system"
    )


    execute(
        "mkdir -p /etc/nginx/sites-available"
    )





def start_docker():


    print(
        "Starting TwinChat containers..."
    )


    execute(
        "docker compose down"
    )


    execute(
        "docker compose up -d --build"
    )





def django_prepare():


    print(
        "Preparing Django..."
    )


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


    with open(
        "/etc/systemd/system/twinchat.service",
        "w"
    ) as file:

        file.write(service)



    execute(
        "systemctl daemon-reload"
    )


    execute(
        "systemctl enable twinchat"
    )





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


    path = (
        "/etc/nginx/sites-available/"
        f"{NGINX_NAME}.conf"
    )


    with open(
        path,
        "w"
    ) as file:

        file.write(nginx)



    execute(
        f"""
ln -sf {path}
/etc/nginx/sites-enabled/{NGINX_NAME}.conf
"""
    )



    execute(
        "nginx -t"
    )


    execute(
        "systemctl restart nginx"
    )





def start_services():


    execute(
        "systemctl restart twinchat"
    )


    execute(
        "systemctl restart nginx"
    )





def deploy():


    banner()


    install_packages()

    create_directories()

    start_docker()

    django_prepare()

    create_gunicorn_service()

    create_nginx()

    start_services()



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

    deploy()