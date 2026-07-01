import os
import subprocess
import sys
import time
import shutil


class DeployError(Exception):
    pass


def execute(command, cwd=None):
    print(f"\n{'=' * 60}")
    print(f"  $ {command}")
    print(f"{'=' * 60}")

    try:
        result = subprocess.run(
            command,
            shell=True,
            check=True,
            cwd=cwd,
            text=True,
        )
        return result
    except subprocess.CalledProcessError as e:
        raise DeployError(
            f"Command failed (code {e.returncode}): {command}"
        ) from e
    except FileNotFoundError as e:
        raise DeployError(
            f"Command not found: {command}"
        ) from e


def banner():
    print(
        r"""
  _____ _____ ____  __  __ ____  _     ___   ____
 |_   _| ____|  _ \|  \/  | __ )| |   / _ \ / ___|
   | | |  _| | |_) | |\/| |  _ \| |  | | | | |  _
   | | | |___|  _ <| |  | | |_) | |__| |_| | |_| |
   |_| |_____|_| \_\_|  |_|____/|_____\___/ \____|

        PRODUCTION DEPLOYER v2.0
        Docker + Nginx + PostgreSQL + Redis
"""
    )


def check_docker():
    if shutil.which("docker") is None:
        raise DeployError("Docker is not installed or not in PATH")

    if shutil.which("docker") is None or "compose" not in subprocess.run(
        "docker compose version", shell=True, capture_output=True, text=True
    ).stdout.lower():
        raise DeployError("Docker Compose is not available")

    print("[OK] Docker and Docker Compose are available")


def check_env_file():
    env_path = os.path.join(os.path.dirname(__file__), ".env")
    example_path = os.path.join(os.path.dirname(__file__), ".env.example")

    if not os.path.exists(env_path):
        if os.path.exists(example_path):
            shutil.copy2(example_path, env_path)
            print("[INFO] Created .env from .env.example")
            print("[WARN] Edit .env with your production values before going live!")
        else:
            raise DeployError(".env file not found and .env.example missing")


def build_and_start():
    print("\n--- Building and starting containers ---")
    execute("docker compose down --remove-orphans")
    execute("docker compose build --no-cache")
    execute("docker compose up -d")


def wait_for_services():
    print("\n--- Waiting for services to be ready ---")
    max_attempts = 30
    for i in range(max_attempts):
        result = subprocess.run(
            "docker compose ps --format json",
            shell=True,
            capture_output=True,
            text=True,
            cwd=os.path.dirname(__file__),
        )
        output = result.stdout
        if '"running"' in output or '"Up"' in output:
            print("[OK] Containers are running")
            break
        print(f"  Waiting... ({i + 1}/{max_attempts})")
        time.sleep(2)
    else:
        print("[WARN] Some containers may not be fully ready yet")

    print("  Waiting 10s for database initialization...")
    time.sleep(10)


def django_migrate():
    print("\n--- Running Django migrations ---")
    execute("docker compose exec -T backend python manage.py migrate --noinput")


def django_collectstatic():
    print("\n--- Collecting static files ---")
    execute("docker compose exec -T backend python manage.py collectstatic --noinput")


def show_status():
    print("\n--- Container status ---")
    execute("docker compose ps")


def print_success():
    print(
        r"""
============================================
  TwinChat deployed successfully!
============================================

  Services:
    - PostgreSQL    : localhost:5432
    - Redis         : localhost:6379
    - Django API    : localhost (via Nginx)
    - WebSocket     : ws://localhost/ws/
    - Nginx         : localhost:80
    - Static files  : served by Nginx

  Commands:
    - docker compose ps          : check status
    - docker compose logs -f     : view logs
    - docker compose down        : stop all
    - docker compose restart     : restart all

============================================
"""
    )


def deploy():
    banner()

    steps = [
        ("Checking Docker", check_docker),
        ("Checking .env file", check_env_file),
        ("Building and starting containers", build_and_start),
        ("Waiting for services", wait_for_services),
        ("Running Django migrations", django_migrate),
        ("Collecting static files", django_collectstatic),
        ("Showing status", show_status),
    ]

    for step_name, step_func in steps:
        try:
            step_func()
        except DeployError as e:
            print(f"\n  ERROR at '{step_name}': {e}")
            sys.exit(1)
        except Exception as e:
            print(f"\n  UNEXPECTED ERROR at '{step_name}': {e}")
            sys.exit(1)

    print_success()


if __name__ == "__main__":
    try:
        deploy()
    except KeyboardInterrupt:
        print("\nDeployment cancelled by user.")
        sys.exit(130)
