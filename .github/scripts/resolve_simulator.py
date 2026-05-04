#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
from typing import Optional


IOS_RUNTIME_PREFIX = "com.apple.CoreSimulator.SimRuntime.iOS-"


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resolve one available iOS simulator by name and runtime version."
    )
    parser.add_argument("--ios-version", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument(
        "--simulators-json",
        help="Optional simctl JSON file path for local validation.",
    )
    return parser.parse_args()


def load_simulators(simulators_json_path: Optional[str]) -> dict:
    if simulators_json_path:
        with open(simulators_json_path) as file:
            return json.load(file)

    result = subprocess.run(
        ["xcrun", "simctl", "list", "devices", "available", "--json"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print("Failed to list available simulators.", file=sys.stderr)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
        raise SystemExit(result.returncode)

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        print(f"Failed to parse simctl JSON output: {error}", file=sys.stderr)
        raise SystemExit(1)


def runtime_id(ios_version: str) -> str:
    return f"{IOS_RUNTIME_PREFIX}{ios_version.replace('.', '-')}"


def print_available_ios_devices(simulators: dict) -> None:
    print("Available iOS simulator devices:", file=sys.stderr)
    for runtime, devices in sorted(simulators.get("devices", {}).items()):
        if not runtime.startswith(IOS_RUNTIME_PREFIX):
            continue

        version = runtime.removeprefix(IOS_RUNTIME_PREFIX).replace("-", ".")
        names = sorted(
            {
                device.get("name", "<unknown>")
                for device in devices
                if device.get("isAvailable")
            }
        )
        if names:
            print(f"  iOS {version}: {', '.join(names)}", file=sys.stderr)


def main() -> int:
    arguments = parse_arguments()
    simulators = load_simulators(arguments.simulators_json)
    matching_devices = [
        device
        for device in simulators.get("devices", {}).get(runtime_id(arguments.ios_version), [])
        if device.get("name") == arguments.name and device.get("isAvailable")
    ]

    if len(matching_devices) != 1:
        print(
            f"Expected exactly one available {arguments.name} simulator for iOS {arguments.ios_version}; found {len(matching_devices)}.",
            file=sys.stderr,
        )
        print_available_ios_devices(simulators)
        return 1

    print(matching_devices[0]["udid"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
