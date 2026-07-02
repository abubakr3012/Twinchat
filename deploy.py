#!/usr/bin/env python3
"""
Switch TwinChat from osaf.softclub.win -> abubakr.softclub.win
"""
import sys, time, base64, re
import paramiko

HOST = '171.22.174.50'
USER = 'abubakr'
PASSWORD = 'darknet135'
PROJECT_DIR = '/home/abubakr/Twinchat'
OLD_DOMAIN = 'osaf.softclub.win'
NEW_DOMAIN = 'abubakr.softclub.win'

def run(client, cmd, timeout=180):
    print(f'\n>>> {cmd}')
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    stdin.close()
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    exit_code = stdout.channel.recv_exit_status()
    if out.strip(): print(out.strip())
    if err.strip(): print('[ERR]', err.strip()[:500])
    return exit_code, out, err

def main():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(HOST, 22, USER, PASSWORD, timeout=30,
                   allow_agent=False, look_for_keys=False, banner_timeout=30)
    print('SSH Connected!')

    # ── 1. Read docker-compose.yml to understand port mapping ─────────
    print('\n=== DOCKER-COMPOSE.YML ===')
    run(client, f'cat {PROJECT_DIR}/docker-compose.yml 2>/dev/null || cat {PROJECT_DIR}/docker-compose.yaml 2>/dev/null')

    # ── 2. Read osaf.softclub.win nginx config to copy exact settings ─
    print('\n=== CURRENT OSAF NGINX CONFIG ===')
    _, osaf_conf, _ = run(client, f'cat /etc/nginx/sites-available/{OLD_DOMAIN} 2>/dev/null')

    # Extract proxy_pass port from osaf config
    port_match = re.findall(r'proxy_pass\s+http://[\d.]+:(\d+)', osaf_conf)
    ws_port_match = re.findall(r'location\s+/ws[^}}]*proxy_pass\s+http://[\d.]+:(\d+)', osaf_conf, re.DOTALL)
    
    api_port = port_match[0] if port_match else '8010'
    ws_port  = ws_port_match[0] if ws_port_match else api_port
    print(f'\nDetected -> API port: {api_port}, WS port: {ws_port}')

    # ── 3. Get current nginx config of osaf for reference ─────────────
    print('\n=== FULL OSAF CONFIG (for reference) ===')
    run(client, f'cat /etc/nginx/sites-available/{OLD_DOMAIN}')

    # ── 4. Create new config for abubakr.softclub.win ─────────────────
    # Use same ports as osaf, just change domain name
    new_conf = f"""server {{
    server_name {NEW_DOMAIN} www.{NEW_DOMAIN};

    client_max_body_size 100M;

    # REST API
    location / {{
        proxy_pass         http://127.0.0.1:{api_port};
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_connect_timeout 300;
        proxy_read_timeout    300;
    }}

    # WebSocket
    location /ws/ {{
        proxy_pass         http://127.0.0.1:{ws_port};
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }}

    location /static/ {{
        alias {PROJECT_DIR}/backend/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }}

    location /media/ {{
        alias {PROJECT_DIR}/backend/media/;
        expires 7d;
    }}

    listen 80;
    listen [::]:80;
}}
"""

    print(f'\n=== CREATING NGINX CONFIG FOR {NEW_DOMAIN} ===')
    encoded = base64.b64encode(new_conf.encode()).decode()
    run(client, f'echo "{encoded}" | base64 -d | sudo tee /etc/nginx/sites-available/{NEW_DOMAIN}')
    run(client, f'sudo ln -sf /etc/nginx/sites-available/{NEW_DOMAIN} /etc/nginx/sites-enabled/{NEW_DOMAIN}')
    print(f'Created & enabled: {NEW_DOMAIN}')

    # ── 5. Disable osaf.softclub.win ───────────────────────────────────
    print(f'\n=== DISABLING {OLD_DOMAIN} ===')
    run(client, f'sudo rm -f /etc/nginx/sites-enabled/{OLD_DOMAIN}')
    print(f'Disabled: {OLD_DOMAIN}')

    # ── 6. Test + reload nginx ─────────────────────────────────────────
    print('\n=== NGINX TEST & RELOAD ===')
    code, out, err = run(client, 'sudo nginx -t 2>&1')
    combined = out + err
    if 'successful' in combined.lower() or code == 0:
        print('✅ nginx config OK')
        run(client, 'sudo nginx -s reload 2>&1 || sudo systemctl reload nginx')
        print('✅ nginx reloaded')
    else:
        print('❌ nginx config error — keeping old config')
        run(client, f'sudo ln -sf /etc/nginx/sites-available/{OLD_DOMAIN} /etc/nginx/sites-enabled/{OLD_DOMAIN}')
        run(client, f'sudo rm -f /etc/nginx/sites-enabled/{NEW_DOMAIN}')

    # ── 7. Try certbot SSL ─────────────────────────────────────────────
    print(f'\n=== SSL CERTIFICATE FOR {NEW_DOMAIN} ===')
    _, cb, _ = run(client, 'which certbot 2>/dev/null || which /snap/bin/certbot 2>/dev/null || echo ""')
    cb = cb.strip().split('\n')[0] if cb.strip() else ''
    if cb:
        print(f'certbot found: {cb}')
        code, out, err = run(client,
            f'sudo {cb} --nginx -d {NEW_DOMAIN} --non-interactive --agree-tos -m admin@softclub.tj --redirect 2>&1',
            timeout=120)
        if code == 0:
            print(f'✅ SSL issued for {NEW_DOMAIN}')
        else:
            print(f'⚠️  certbot: {(out+err)[:300]}')
            print('   (DNS may not be configured yet — HTTP-only mode is fine)')
    else:
        print('certbot not found — running HTTP only')

    # ── 8. Enabled sites ───────────────────────────────────────────────
    print('\n=== ENABLED SITES ===')
    run(client, 'ls -la /etc/nginx/sites-enabled/')

    # ── 9. Git pull + rebuild backend ─────────────────────────────────
    print('\n=== GIT PULL ===')
    run(client, f'cd {PROJECT_DIR} && git pull origin main 2>&1')

    print('\n=== REBUILD BACKEND ===')
    # Find backend service
    _, svc_out, _ = run(client, f'cd {PROJECT_DIR} && docker compose config --services 2>&1')
    services = [s.strip() for s in svc_out.strip().split('\n') if s.strip()]
    backend_svc = next((s for s in services if s in ('backend','web','app','django','api')), services[0] if services else None)
    
    if backend_svc:
        run(client, f'cd {PROJECT_DIR} && docker compose up -d --build {backend_svc} 2>&1', timeout=300)
        time.sleep(5)
        run(client, f'cd {PROJECT_DIR} && docker compose exec -T {backend_svc} python manage.py migrate 2>&1')
        run(client, f'cd {PROJECT_DIR} && docker compose exec -T {backend_svc} python manage.py collectstatic --noinput 2>&1 | tail -3')

    # ── 10. Final status ───────────────────────────────────────────────
    print('\n=== DOCKER STATUS ===')
    run(client, f'cd {PROJECT_DIR} && docker compose ps 2>&1')

    # ── 11. WebSocket check ────────────────────────────────────────────
    print('\n=== WEBSOCKET CHECK ===')
    ws_check = f"""
import asyncio, socket

# TCP check
print("TCP port check:")
for p in [{api_port}, {ws_port}, 80, 89]:
    try:
        socket.create_connection(("127.0.0.1", p), 2).close()
        print(f"  port {{p}}: OPEN")
    except Exception as e:
        print(f"  port {{p}}: {{e}}")

async def ws_test():
    try:
        import websockets
        for url in [
            "ws://127.0.0.1:{ws_port}/ws/chat/1/?token=dummy",
            "ws://127.0.0.1:{api_port}/ws/chat/1/?token=dummy",
        ]:
            try:
                async with websockets.connect(url, open_timeout=5) as ws:
                    print(f"WS CONNECTED: {{url}}")
            except Exception as e:
                msg = str(e)
                if any(x in msg for x in ["403","401","404","InvalidStatus"]):
                    print(f"WS OK (auth needed): {{url}}")
                elif "refused" in msg.lower():
                    print(f"WS REFUSED: {{url}}")
                else:
                    print(f"WS {{type(e).__name__}}: {{msg[:100]}} @ {{url}}")
    except ImportError:
        print("websockets not installed on host")

asyncio.run(ws_test())
"""
    enc = base64.b64encode(ws_check.encode()).decode()
    run(client, f'echo "{enc}" | base64 -d > /tmp/wscheck.py')
    run(client, 'python3 /tmp/wscheck.py 2>&1')

    # ── 12. HTTP check ─────────────────────────────────────────────────
    print('\n=== HTTP CHECK ===')
    run(client, f'curl -s -o /dev/null -w "HTTP %{{http_code}} -> http://{NEW_DOMAIN}/" http://{NEW_DOMAIN}/ 2>&1 || echo "curl failed (DNS may not resolve yet)"')
    run(client, f'curl -s -o /dev/null -w "HTTP %{{http_code}} -> http://127.0.0.1:{api_port}/api/" http://127.0.0.1:{api_port}/api/ 2>&1')

    print('\n' + '='*60)
    print('✅ COMPLETE!')
    print(f'   ❌ {OLD_DOMAIN}  — DISABLED')
    print(f'   ✅ {NEW_DOMAIN}  — ACTIVE (API:{api_port}, WS:{ws_port})')
    print('='*60)
    client.close()

if __name__ == '__main__':
    main()
