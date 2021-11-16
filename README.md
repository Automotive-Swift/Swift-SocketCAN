# Swift-SocketCAN

Access the Linux [SocketCAN](https://www.kernel.org/doc/html/latest/networking/can.html) API from Swift.

## How to integrate

This is an SPM-compliant Swift Package: First, add the following line in `Package.swift` to your package dependencies:

```swift
.package(url: "https://github.com/AutomotiveSwift/Swift-SocketCAN.git", from: "0.9.0")
```

Then, add the module `Swift-SocketCAN` – where necessary – to your target dependencies.

## Usage

Send a CAN frame to `0x18db33f1` (OBD2 29-bit broadcast address) via interface `can0`:

```swift
let socket = SocketCAN(iface: "can0")
do {
    socket.open(baudrate: 500000)

    let frame = Frame(id: 0x18db33f1, padded: [0x10, 0x01])
    try socket.write(frame: frame)
} catch {
    print("An error occured: \(error)")
}
```

Read CAN frames from `can0` and dump them to the console:

```swift
let socket = SocketCAN(iface: "can0")
try! socket.open()

while true {
    do {
        let frame = socket.read(timeout: 500)
        var str = "\(socket.iface) \(frame.timestamp): [\(frame.dlc)]"
        for i in 0..<frame.dlc {
            str += String(format: " %02X", frame.data[i])
        }
        print(str)
    } catch SocketCAN.Error.timeout {
        // timeout, just continue
    } catch {
        print("error: \(error)")
    }
}
```

## Status

This has only received minimal testing yet, but it seems to work so far.
Early tests with making this an `actor` on Swift 5.5 have failed, but I've not
given up yet.

## Roadmap

- [x] Add ISOTP support
- [ ] Add Device support (start, stop, set bitrate, queue length?)

## License and Contributions

This package is licensed under the term of the MIT License.
Contributions are always welcome!