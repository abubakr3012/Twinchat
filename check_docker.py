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

run("cd /home/abubakr/Twinchat && docker compose logs --tail=50 websocket")
client.close()
