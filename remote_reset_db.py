import paramiko

def reset_passwords():
    host = "171.22.174.50"
    user = "abubakr"
    secret = "darknet135"
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(host, username=user, password=secret, timeout=15)
        cmd = "cd Twinchat && docker compose exec -T backend python manage.py shell -c \"from django.contrib.auth import authenticate; print('Auth result:', authenticate(username='ali4', password='123456'))\""
        stdin, stdout, stderr = ssh.exec_command(cmd)
        print("Output:", stdout.read().decode('utf-8'))
        print("Error:", stderr.read().decode('utf-8'))
    except Exception as e:
        print("Failed to reset:", e)
    finally:
        ssh.close()

if __name__ == '__main__':
    reset_passwords()
