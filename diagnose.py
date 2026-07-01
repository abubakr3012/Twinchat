import os
import sys
import socket
import subprocess
import urllib.request
import re
import json

try:
    from colorama import init, Fore, Back, Style
except ImportError:
    print("Модуль colorama не установлен. Установите его командой: pip install colorama")
    sys.exit(1)

init(autoreset=True)


def print_header(title):
    line = "=" * 60
    print("\n" + Fore.CYAN + Style.BRIGHT + line)
    print(Fore.CYAN + Style.BRIGHT + f"  {title}")
    print(Fore.CYAN + Style.BRIGHT + line)


def print_ok(msg):
    print(f" {Fore.GREEN}{Style.BRIGHT}[+] [OK]{Style.RESET_ALL} {msg}")


def print_warn(msg):
    print(f" {Fore.YELLOW}{Style.BRIGHT}[!] [WARN]{Style.RESET_ALL} {msg}")


def print_error(msg):
    print(f" {Fore.RED}{Style.BRIGHT}[-] [ERROR]{Style.RESET_ALL} {msg}")


def print_info(msg):
    print(f" {Fore.BLUE}{Style.BRIGHT}[i]{Style.RESET_ALL} {msg}")


def check_port(host, port):
    try:
        with socket.create_connection((host, port), timeout=2):
            return True
    except (socket.timeout, ConnectionRefusedError, OSError):
        return False


def check_environment():
    print_header("1. ПРОВЕРКА ОКРУЖЕНИЯ (.env & Сервисы)")

    env_path = ".env"
    if not os.path.exists(env_path):
        print_error(f"Файл {env_path} не найден в корневой директории!")
        return False

    print_ok("Файл .env найден.")

    # Read variables
    env_vars = {}
    with open(env_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                parts = line.split("=", 1)
                if len(parts) == 2:
                    env_vars[parts[0].strip()] = parts[1].strip()

    # Check Postgres
    postgres_host = env_vars.get("POSTGRES_HOST", "127.0.0.1")
    postgres_port = int(env_vars.get("POSTGRES_PORT", "5432"))
    if check_port(postgres_host, postgres_port):
        print_ok(f"PostgreSQL доступен по адресу {postgres_host}:{postgres_port}")
    else:
        print_error(f"Не удалось подключиться к PostgreSQL ({postgres_host}:{postgres_port})! Убедитесь, что служба запущена.")

    # Check Redis
    redis_url = env_vars.get("REDIS_URL", "redis://127.0.0.1:6379/0")
    # Extract host and port from URL
    match = re.search(r"redis://([^:]+):(\d+)", redis_url)
    if match:
        redis_host, redis_port = match.group(1), int(match.group(2))
    else:
        redis_host, redis_port = "127.0.0.1", 6379

    if check_port(redis_host, redis_port):
        print_ok(f"Redis доступен по адресу {redis_host}:{redis_port}")
    else:
        print_error(f"Не удалось подключиться к Redis ({redis_host}:{redis_port})! Убедитесь, что служба запущена.")


def check_django_backend():
    print_header("2. ПРОВЕРКА БЭКЕНДА (Django)")

    if check_port("127.0.0.1", 8000):
        print_ok("Django сервер запущен на порту 8000.")
        # Test Django API health
        try:
            url = "http://127.0.0.1:8000/api/users/login/"
            req = urllib.request.Request(url, data=b"{}", headers={'Content-Type': 'application/json'})
            with urllib.request.urlopen(req, timeout=3) as response:
                pass
            print_ok("Django API отвечает корректно (метод POST login вернул статус).")
        except urllib.error.HTTPError as e:
            if e.code == 400:  # Bad Request because of empty body is normal
                print_ok("Django API отвечает на HTTP-запросы.")
            else:
                print_warn(f"Django API вернул HTTP код {e.code}")
        except Exception as e:
            print_error(f"Ошибка при запросе к Django API: {e}")
    else:
        print_error("Django сервер не запущен на порту 8000! Запустите его командой: python backend/manage.py runserver 0.0.0.0:8000")

    # Run Django checks
    try:
        print_info("Выполнение Django system check...")
        res = subprocess.run([sys.executable, "backend/manage.py", "check"], capture_output=True, text=True, check=True)
        print_ok("Django system check прошел успешно.")
    except subprocess.CalledProcessError as e:
        print_error("Django system check обнаружил ошибки:")
        print(Fore.RED + (e.stderr or e.stdout))

    # Check migrations
    try:
        print_info("Проверка миграций Django...")
        res = subprocess.run([sys.executable, "backend/manage.py", "showmigrations"], capture_output=True, text=True, check=True)
        unapplied = [line for line in res.stdout.splitlines() if "[ ]" in line]
        if unapplied:
            print_warn(f"Найдены непримененные миграции ({len(unapplied)} шт.):")
            for m in unapplied[:5]:
                print(Fore.YELLOW + f"    {m}")
            print_warn("Примените их командой: python backend/manage.py migrate")
        else:
            print_ok("Все миграции Django успешно применены.")
    except subprocess.CalledProcessError as e:
        print_error(f"Не удалось проверить миграции Django: {e.stderr or e.stdout}")


def check_flutter_app():
    print_header("3. ПРОВЕРКА КЛИЕНТА (Flutter)")

    # 1. Check local IP configuration in api_constants.dart
    constants_path = "app/lib/core/api/api_constants.dart"
    if os.path.exists(constants_path):
        with open(constants_path, "r", encoding="utf-8") as f:
            content = f.read()

        ip_match = re.search(r"baseUrl\s*=\s*['\"]http://([^:/]+)", content)
        if ip_match:
            config_ip = ip_match.group(1)
            print_ok(f"В api_constants.dart настроен IP: {config_ip}")

            # Find local IP
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                s.connect(("8.8.8.8", 80))
                local_ip = s.getsockname()[0]
                s.close()
                print_ok(f"Ваш текущий локальный IP-адрес: {local_ip}")

                if config_ip != local_ip and config_ip != "localhost" and config_ip != "127.0.0.1":
                    print_warn(f"Внимание! Настроенный IP ({config_ip}) не совпадает с вашим текущим IP ({local_ip}).")
                    print_warn("Если вы запускаете приложение на физическом телефоне, измените IP в api_constants.dart на локальный IP компьютера.")
            except Exception:
                print_warn("Не удалось определить локальный IP компьютера.")
        else:
            print_error("Не удалось найти baseUrl в api_constants.dart!")
    else:
        print_error(f"Файл {constants_path} не найден!")

    # 2. Run flutter analyze
    print_info("Запуск flutter analyze для проверки ошибок компиляции (это займет некоторое время)...")
    try:
        res = subprocess.run("flutter analyze", shell=True, capture_output=True, text=True, cwd="app")
        if res.returncode == 0:
            print_ok("Flutter static analysis прошел без критических ошибок.")
        else:
            print_error("В коде Flutter найдены ошибки или предупреждения:")
            lines = res.stdout.splitlines()
            errors = [line for line in lines if "error -" in line]
            warnings = [line for line in lines if "info -" in line or "warning -" in line]

            if errors:
                print_error(f"Критические ошибки ({len(errors)} шт.):")
                for err in errors[:10]:
                    print(Fore.RED + f"  {err}")
            if warnings:
                print_warn(f"Предупреждения/инфо ({len(warnings)} шт.):")
                for warn in warnings[:10]:
                    print(Fore.YELLOW + f"  {warn}")
    except FileNotFoundError:
        print_error("Утилита flutter не найдена в PATH! Убедитесь, что Flutter SDK установлен.")
    except Exception as e:
        print_error(f"Не удалось запустить flutter analyze: {e}")


def main():
    banner = "=" * 60
    print(Fore.MAGENTA + Style.BRIGHT + banner)
    print(Fore.MAGENTA + Style.BRIGHT + "          ДИАГНОСТИЧЕСКИЙ СКРИПТ TWINCHAT")
    print(Fore.MAGENTA + Style.BRIGHT + banner)

    check_environment()
    check_django_backend()
    check_flutter_app()

    print_header("ДИАГНОСТИКА ЗАВЕРШЕНА")


if __name__ == "__main__":
    main()