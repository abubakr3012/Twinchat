import paramiko
import base64

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('171.22.174.50', port=22, username='abubakr', password='darknet135', timeout=10)

def run(cmd):
    print(">>>", cmd)
    stdin, stdout, stderr = client.exec_command(cmd)
    out = stdout.read().decode()
    err = stderr.read().decode()
    print(out)
    if err: print("[ERR]", err)

conf = """server {
    server_name abubakr.softclub.win www.abubakr.softclub.win;

    client_max_body_size 100M;

    # REST API
    location / {
        proxy_pass         https://127.0.0.1:89;
        proxy_ssl_verify   off;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_connect_timeout 300;
        proxy_read_timeout    300;
    }

    # WebSocket
    location /ws/ {
        proxy_pass         https://127.0.0.1:89;
        proxy_ssl_verify   off;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }

    listen 80;
    listen [::]:80;
}
"""

encoded = base64.b64encode(conf.encode()).decode()

run("echo 'darknet135' | sudo -S rm -f /tmp/new_conf")
run(f"echo '{encoded}' | base64 -d > /tmp/new_conf")
run("echo 'darknet135' | sudo -S mv /tmp/new_conf /etc/nginx/sites-available/abubakr.softclub.win")
run("echo 'darknet135' | sudo -S ln -sf /etc/nginx/sites-available/abubakr.softclub.win /etc/nginx/sites-enabled/abubakr.softclub.win")
run("echo 'darknet135' | sudo -S nginx -t")
run("echo 'darknet135' | sudo -S systemctl reload nginx")

# SSL attempt using certbot if possible
run("echo 'darknet135' | sudo -S certbot --nginx -d abubakr.softclub.win --non-interactive --agree-tos -m admin@softclub.tj --redirect")

client.close()
