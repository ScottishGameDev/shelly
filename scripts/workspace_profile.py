#!/usr/bin/env python3
import json
import os
import signal
import subprocess
import sys
from pathlib import Path


def load_profile(path: Path) -> tuple[int, list[list[str]]]:
    document = json.loads(path.read_text(encoding="utf-8"))
    profile = document.get("workspace2", {})
    workspace_id = profile.get("id", 2)
    apps = profile.get("apps", [])
    if not isinstance(workspace_id, int) or workspace_id < 1:
        raise ValueError("workspace2.id must be a positive integer")
    if not isinstance(apps, list) or any(
        not isinstance(command, list)
        or not command
        or any(not isinstance(part, str) or not part for part in command)
        for command in apps
    ):
        raise ValueError("workspace2.apps must contain non-empty command arrays")
    return workspace_id, apps


def launch(workspace_id: int, apps: list[list[str]]) -> None:
    subprocess.run(["hyprctl", "dispatch", "workspace", str(workspace_id)], check=True)
    for command in apps:
        subprocess.Popen(
            command,
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def close(workspace_id: int) -> None:
    clients = json.loads(subprocess.check_output(["hyprctl", "clients", "-j"]))
    for client in clients:
        if client.get("workspace", {}).get("id") == workspace_id:
            process_id = client.get("pid")
            if isinstance(process_id, int) and process_id > 1:
                try:
                    os.kill(process_id, signal.SIGTERM)
                except ProcessLookupError:
                    pass


def main() -> int:
    if len(sys.argv) != 3 or sys.argv[1] not in {"launch", "close"}:
        print("usage: workspace_profile.py launch|close CONFIG", file=sys.stderr)
        return 2
    workspace_id, apps = load_profile(Path(sys.argv[2]))
    if sys.argv[1] == "launch":
        launch(workspace_id, apps)
    else:
        close(workspace_id)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError, subprocess.CalledProcessError) as error:
        print(f"workspace_profile: {error}", file=sys.stderr)
        raise SystemExit(1)
