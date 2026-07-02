import paramiko
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

run("echo 'darknet135' | sudo -S sed -i 's|http://127.0.0.1:89|https://127.0.0.1:89|g' /etc/nginx/sites-available/abubakr.softclub.win")
run("echo 'darknet135' | sudo -S sed -i '/proxy_pass.*https.*/a \\        proxy_ssl_verify off;' /etc/nginx/sites-available/abubakr.softclub.win")
run("echo 'darknet135' | sudo -S nginx -t")
run("echo 'darknet135' | sudo -S systemctl reload nginx")

# Test HTTP -> HTTPS proxying
run("curl -k -s -o /dev/null -w \"HTTP %{http_code}\" https://abubakr.softclub.win/api/")
run("curl -k -s -o /dev/null -w \"HTTP %{http_code}\" https://127.0.0.1:89/api/")

client.close()
