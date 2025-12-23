# Rachel TRS-80 Client

Render-only client for the Rachel card game, connecting to an iOS host via TRS-IO WiFi adapter.

## Requirements

- TRS-80 Model I, III, or 4
- TRS-IO WiFi adapter
- [zmac](http://48k.ca/zmac.html) Z80 assembler

## Building

```bash
# Build
make

# Output: build/rachel.cmd (TRS-DOS executable)
```

## Hardware Setup

Install the TRS-IO adapter. The client uses the TRS-IO TCP/IP API for network connectivity.

## Network Configuration

On startup, enter the host address in the format:
```
HOST:PORT> 192.168.1.100:6502
```

## Architecture

This is a **render-only client** - the iOS host runs the game engine and sends display state via the RUBP binary protocol. The TRS-80:

1. Connects to host via TCP/IP (TRS-IO)
2. Receives game state updates (64-byte RUBP messages)
3. Renders the game display (64x16 text mode)
4. Sends player input back to host

## File Structure

```
src/
  main.asm       - Entry point, main loop
  display.asm    - Video RAM text output
  input.asm      - Keyboard handling
  game.asm       - Game screen rendering
  connect.asm    - Connection UI
  rubp.asm       - RUBP protocol encoding/decoding
  net/
    trsio.asm    - TRS-IO TCP driver
```

## Protocol

Uses RUBP (Rachel Unified Binary Protocol) - 64-byte fixed messages with 16-byte header and 48-byte payload. See `docs/PROTOCOL.md` in the main Rachel repository.

## Related Projects

- [rachel-ios](https://github.com/rachel-multiverse/rachel-ios) - iOS host application
- [rachel-zx-spectrum](https://github.com/rachel-multiverse/rachel-zx-spectrum) - ZX Spectrum client
- [rachel-msx](https://github.com/rachel-multiverse/rachel-msx) - MSX client
