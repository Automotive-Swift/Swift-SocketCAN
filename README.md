# Swift-SocketCAN

Access the Linux [SocketCAN](https://www.kernel.org/doc/html/latest/networking/can.html) API from Swift.

With Swift 5.5 (and later), the API is exposed via an `actor`,
if you're using an older compiler, you'll get a standard `class`.

## How to integrate

This is an SPM-compliant Swift Package.

## Usage

Send a CAN frame to `0x18db33f1` (OBD2 29-bit broadcast address) via interface `toucan1`:

```swift
let socket = SocketCAN(iface: "toucan1")
do {
    try await socket.open()

    let frame = Frame(id: 0x18db33f1, padded: [0x10, 0x01])
    try await socket.write(frame: frame)
} catch {
    print("An error occured: \(error)")
}
```

Read CAN frames from `toucan1` and dump them to the console:

```swift
let socket = SocketCAN(iface: "toucan1")
try! await socket.open()

while true {
    do {
        let frame = try await socket.read(timeout: 500)
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

## Status and Roadmap

This has only received minimal testing yet, but it seems to work so far.

Eventually I want to expose the CAN API also via an `AsyncSequence`.

## License and Contributions

This package is licensed under the term of the MIT License.
Contributions are always welcome!