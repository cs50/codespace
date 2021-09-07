#!/usr/bin/env python3

import asyncio
import json
import sys
import websockets

SOCKET_URI = "ws://localhost:60001"

async def execute(command):
    websocket = await websockets.connect(SOCKET_URI)
    
    args = ""
    if len(sys.argv) > 2:
        args = sys.argv[2:]
    
    payload = {
        "command": "execute_command",
        "payload": {
            "command": command,
            "args": args
        }
    }
    await websocket.send(json.dumps(payload))


def rebuild():
    command = "github.codespaces.rebuildEnvironment"
    asyncio.get_event_loop().run_until_complete(execute(command))


def main():
    try:
        asyncio.get_event_loop().run_until_complete(execute(sys.argv[1]))
    except:
        print("Usage: command50 COMMAND")


if __name__ == "__main__":
    main()