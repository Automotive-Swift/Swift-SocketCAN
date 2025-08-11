# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Testing
```bash
# Build the package
swift build

# Run all tests
swift test

# Run specific test target
swift test --filter Swift-SocketCANTests
swift test --filter Swift-SocketCAN-ISOTPTests

# Build in release mode
swift build -c release
```

### Platform Requirements
This package **only works on Linux** (requires Linux >= 5.10). The code uses compile-time checks (`#if !os(Linux)`) to prevent compilation on other platforms.

## Architecture Overview

### Core Components

**Swift-SocketCAN** is a Swift wrapper around the Linux SocketCAN API for CAN bus communication. The project consists of three main targets:

#### 1. CSocketCAN (C Layer)
- Location: `Sources/CSocketCAN/`
- Low-level C implementation that interfaces directly with Linux SocketCAN
- Key files:
  - `socketcan.c` - Core socket operations (open, read, write, close)
  - `socketcan-isotp.c` - ISOTP (ISO-TP) protocol implementation
  - `libsocketcan.c` - Interface configuration utilities
- Provides C functions called by Swift layer

#### 2. Swift-SocketCAN (Main Interface)
- Location: `Sources/Swift-SocketCAN/SocketCAN.swift`
- Main Swift API implementing `CAN.Interface` protocol from Swift-CAN dependency
- Key class: `SocketCAN` - blocking, non-thread-safe CAN communication
- Features:
  - Frame conversion between Swift and C structures
  - Support for both 11-bit and 29-bit CAN IDs (sets `CAN_EFF_FLAG` for extended frames)
  - Bitrate configuration (requires root/CAP_NET_ADMIN privileges)
  - Timeout support for read operations

#### 3. Swift-SocketCAN-ISOTP (ISOTP Support)
- Location: `Sources/Swift-SocketCAN-ISOTP/Swift-SocketCAN-ISOTP.swift`
- Implements ISO-TP (ISO 14229-2) transport protocol for longer messages
- Key class: `ISOTP` - handles request/response pairs with arbitration IDs
- Features fixed-length frames with padding (configurable)

### Key Design Patterns

#### Frame Conversion
The architecture uses extensions on `CAN.Frame` to convert between:
- Swift `CAN.Frame` objects (from Swift-CAN dependency)
- C `can_frame` structures (for SocketCAN API)

Manual tuple handling for data bytes (0-8 bytes) with switch statements for each DLC length.

#### Error Handling
Consistent error mapping from C return codes to Swift `CAN.Error` enum:
- `CAN_UNSUPPORTED` → `canNotSupported`
- `IFACE_NOT_FOUND` → `interfaceNotFound`
- `IFACE_NOT_CAN` → `interfaceNotCan`
- `TIMEOUT` → `timeout`
- `READ_ERROR` → `readError`

### Dependencies
- **Swift-CAN**: Provides common CAN frame structures and protocols
- **Glibc**: Linux system calls and C library functions

### Test Structure
Tests are integration-style and require actual CAN interfaces:
- Hardcoded to use `can0` interface
- Set bitrate to 500kbps
- Tests are more like examples than unit tests
- Tests include both basic CAN and ISOTP functionality

### Limitations and TODOs
- No CANFD support yet (limited to classic CAN frames)
- Not thread-safe (blocking operations)
- Actor-based Swift 5.5+ concurrency experiments mentioned but not implemented
- Missing features: Queue length configuration, BCM (Broadcast Manager) support