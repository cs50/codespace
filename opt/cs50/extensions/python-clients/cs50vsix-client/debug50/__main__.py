#!/usr/bin/env python3

import asyncio
import json
import os
import pathlib
import sys
import websockets

from debug50.colors import red, yellow

DEBUGGER_TIMEOUT = 10
SOCKET_URI = "ws://localhost:60001"

LAUNCH_CONFIG_C = "c"
LAUNCH_CONFIG_PYTHON = "python"

LAUNCH_CONFIG = {
    "version": "0.2.0",
    "configurations": [
        {
            "name": LAUNCH_CONFIG_C,
            "type": "cppdbg",
            "request": "launch",
            "program": "",
            "args": [],
            "stopAtEntry": False,
            "cwd": "${fileDirname}",
            "environment": [],
            "externalConsole": False,
            "MIMode": "gdb",
            "MIDebuggerPath": "gdb",
            "miDebuggerArgs": "-q",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": True
                },
                {
                    "description": "Skip glibc",
                    "text": "-interpreter-exec console \"skip -gfi **/glibc*/**/*.c\""
                }
            ]
        },
        {
            "name": LAUNCH_CONFIG_PYTHON,
            "type": "python",
            "request": "launch",
            "program": "",
            "args": [],
            "console": "integratedTerminal"
        }
    ]
}


async def launch():
    try:

        # Start python debugger
        if get_file_extension(sys.argv[1]) == ".py":
            await asyncio.wait_for(launch_debugger(LAUNCH_CONFIG_PYTHON, sys.argv[1]), timeout=DEBUGGER_TIMEOUT)
        
        # Start c/cpp debugger
        else:
            source = sys.argv[1] + ".c"
            executable = sys.argv[1]
            if (verify_executable(source, executable)):
                await asyncio.wait_for(launch_debugger(LAUNCH_CONFIG_C, source), timeout=DEBUGGER_TIMEOUT)
        
        # Monitoring interactive debugger
        await monitor()

    except IndexError:
        display_usage()

    except asyncio.TimeoutError:
        failed_to_start_debugger()
        
    except OSError as e:
        failed_to_connect_debug_service()


async def launch_debugger(name, filename):
    websocket = await websockets.connect(SOCKET_URI)
    customDebugConfiguration = {
        "path": os.path.abspath(filename),
        "launch_config": get_config(name)
    }
    payload = {
        "command": "start_debugger",
        "payload": customDebugConfiguration
    }
    await websocket.send(json.dumps(payload))
    response = await websocket.recv()
    if response == "no_break_points":
        no_break_points()


async def monitor():
    async with websockets.connect(SOCKET_URI) as websocket:
        response = await websocket.recv()
        if response == "terminated_debugger":
            return


def get_config(config_name):
    if len(sys.argv) > 1:
        for each in filter(lambda x: x["name"]==config_name, LAUNCH_CONFIG["configurations"]):
            each["program"] = f"{os.getcwd()}/{sys.argv[1]}"

            for i in range(2, len(sys.argv)):
                each["args"].append(sys.argv[i])
            
            return each


def get_file_extension(path):
    return pathlib.Path(path).suffix


def verify_executable(source, executable):
    if (not os.path.isfile(source)) or (get_file_extension(source) != ".c"):
        file_not_supported()
    
    if (not os.path.isfile(executable)):
        executable_not_found()

    sourceMTime = pathlib.Path(source).stat().st_mtime_ns
    executableMTime = pathlib.Path(executable).stat().st_mtime_ns
    if (sourceMTime > executableMTime):
        message = "Looks like you've changed your code. Recompile and then re-run debug50!"
        print(yellow(message))
        sys.exit(1)

    return True


def file_not_supported():
    message = "Can't debug this program! Are you sure you're running debug50 on an executable or a Python script?"
    print(yellow(message))
    sys.exit(1)


def executable_not_found():
    message = "Executable not found! Did you compile your code?"
    print(yellow(message))
    sys.exit(1)


def no_break_points():
    message = "Looks like you haven't set any breakpoints. "\
                "Set at least one breakpoint by clicking to the "\
                "left of a line number and then re-run debug50!"
    print(yellow(message))
    sys.exit(1)


def failed_to_start_debugger():
    message = "Could not start debugger"
    print(red(message))
    sys.exit(1)


def failed_to_connect_debug_service():
    message = "Debug service is not ready yet. Please try again."
    print(yellow(message))


def display_usage():
    print("Usage: debug50 PROGRAM [ARGUMENT ...]")


def main():
    asyncio.get_event_loop().run_until_complete(launch())


if __name__ == "__main__":
    main()