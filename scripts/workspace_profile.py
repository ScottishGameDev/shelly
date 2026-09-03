#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import time
from pathlib import Path


def valid_command(command: object) -> bool:
    return (
        isinstance(command, list)
        and bool(command)
        and all(isinstance(part, str) and part for part in command)
    )


def load_profile(path: Path) -> dict:
    document = json.loads(path.read_text(encoding="utf-8"))
    profile = document.get("workspace2", {})
    workspace_id = profile.get("id", 2)
    apps = profile.get("apps", [])
    monitor = profile.get("monitor", "")
    launch_delay_ms = profile.get("launchDelayMs", 1000)
    post_launch = profile.get("postLaunch", [])
    post_launch_delay_ms = profile.get("postLaunchDelayMs", 2000)
    if not isinstance(workspace_id, int) or workspace_id < 1:
        raise ValueError("workspace2.id must be a positive integer")
    if not isinstance(monitor, str):
        raise ValueError("workspace2.monitor must be a string")
    if not isinstance(apps, list) or any(not valid_command(command) for command in apps):
        raise ValueError("workspace2.apps must contain non-empty command arrays")
    if post_launch and not valid_command(post_launch):
        raise ValueError("workspace2.postLaunch must be a command array")
    for name, delay in (
        ("launchDelayMs", launch_delay_ms),
        ("postLaunchDelayMs", post_launch_delay_ms),
    ):
        if isinstance(delay, bool) or not isinstance(delay, int) or delay < 0 or delay > 30000:
            raise ValueError(f"workspace2.{name} must be between 0 and 30000")
    return {
        "id": workspace_id,
        "monitor": monitor,
        "apps": apps,
        "launchDelayMs": launch_delay_ms,
        "postLaunch": post_launch,
        "postLaunchDelayMs": post_launch_delay_ms,
    }


def resolve_command(command: list[str], config_path: Path, workspace_id: int) -> list[str]:
    config_dir = config_path.resolve().parent
    resolved = []
    for part in command:
        value = part.replace("{workspaceId}", str(workspace_id))
        value = os.path.expandvars(os.path.expanduser(value))
        if value.startswith("./") or value.startswith("scripts/"):
            value = str(config_dir / value.removeprefix("./"))
        resolved.append(value)
    return resolved


def launch(profile: dict, config_path: Path) -> None:
    workspace_id = profile["id"]
    if profile["monitor"]:
        subprocess.run(
            ["hyprctl", "dispatch", "focusmonitor", profile["monitor"]], check=True
        )
    subprocess.run(["hyprctl", "dispatch", "workspace", str(workspace_id)], check=True)
    time.sleep(profile["launchDelayMs"] / 1000)
    for command in profile["apps"]:
        subprocess.Popen(
            resolve_command(command, config_path, workspace_id),
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    if profile["postLaunch"]:
        time.sleep(profile["postLaunchDelayMs"] / 1000)
        subprocess.Popen(
            resolve_command(profile["postLaunch"], config_path, workspace_id),
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def workspace_clients(workspace_id: int) -> list[dict]:
    clients = json.loads(subprocess.check_output(["hyprctl", "clients", "-j"]))
    return [
        client
        for client in clients
        if client.get("workspace", {}).get("id") == workspace_id
        and isinstance(client.get("address"), str)
        and client["address"]
    ]


def plan_close(workspace_id: int) -> None:
    for client in workspace_clients(workspace_id):
        print(
            json.dumps(
                {
                    "address": client["address"],
                    "class": client.get("class", ""),
                    "title": client.get("title", ""),
                },
                separators=(",", ":"),
            )
        )


def close(workspace_id: int) -> None:
    for client in workspace_clients(workspace_id):
        subprocess.run(
            ["hyprctl", "dispatch", "closewindow", f"address:{client['address']}"],
            check=False,
        )


def main() -> int:
    if len(sys.argv) != 3 or sys.argv[1] not in {"launch", "close", "plan-close"}:
        print("usage: workspace_profile.py launch|close|plan-close CONFIG", file=sys.stderr)
        return 2
    config_path = Path(sys.argv[2])
    profile = load_profile(config_path)
    if sys.argv[1] == "launch":
        launch(profile, config_path)
    elif sys.argv[1] == "close":
        close(profile["id"])
    else:
        plan_close(profile["id"])
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError, subprocess.CalledProcessError) as error:
        print(f"workspace_profile: {error}", file=sys.stderr)
        raise SystemExit(1)
