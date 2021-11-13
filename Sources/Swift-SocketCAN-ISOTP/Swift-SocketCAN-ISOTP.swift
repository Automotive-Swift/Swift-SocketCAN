// This file is part of Swift-SocketCAN - (C) Dr. Michael 'Mickey' Lauer <mlauer@vanille-media.de>
#if !os(Linux)
#error("This package requires Linux >= 5.10")
#endif

import CSocketCAN
import Glibc
@_exported import Swift_CAN

/// A simple ISOTP SocketCAN communication channel. Blocking operations, not thread-safe.
public class ISOTP {

    let iface: String
    var handle: OpaquePointer?
    var requestId: CAN.ArbitrationId = 0
    var replyId: CAN.ArbitrationId = 0
    var buffer: [UInt8] = .init(repeating: 0, count: 4096)

    /// Create.
    public init(iface: String, variableDLC: Bool = false, padding: UInt8 = 0xAA) {
        self.iface = iface
    }

    /// Open the communication channel.
    public func open(baudrate: Int) throws {
        var handle: SSI? = nil

        // Per default, we're configuring the ISOTP state machine to use fixed length and padding.
        // Might consider making this configurable via the API.
        let result = socketcan_isotp_open(self.iface, 0, 0xAA, &handle)
        switch result {
            case CAN_UNSUPPORTED: throw CAN.Error.canNotSupported
            case IFACE_NOT_FOUND: throw CAN.Error.interfaceNotFound
            case IFACE_NOT_CAN: throw CAN.Error.interfaceNotCan

            default:
                self.handle = handle
        }
    }

    /// Set arbitration ids and write a message, encapsulating via ISOTP.
    public func write(requestId: CAN.ArbitrationId, replyId: CAN.ArbitrationId, bytes: [UInt8]) throws {
        if requestId != self.requestId || replyId != self.replyId {
            socketcan_isotp_set_arbitration(self.handle, requestId, replyId)
            self.requestId = requestId
            self.replyId = replyId
        }
        socketcan_isotp_write(self.handle, bytes, UInt16(bytes.count))
    }

    /// Read an ISOTP answer.
    /// Blocking read the next CAN frame.
    public func read(timeout: Int = 0) throws -> [UInt8] {
        var tv = timeval()
        let nBytes = socketcan_isotp_read(self.handle, &buffer, &tv, Int32(timeout))
        switch nBytes {
            case TIMEOUT:
                throw CAN.Error.timeout
            case READ_ERROR:
                throw CAN.Error.readError
            default:
                return Array(self.buffer[..<Int(nBytes)])
        }
    }

    /// Close the communication channel.
    public func close() {
        socketcan_isotp_close(self.handle)
        self.handle = nil
    }
}