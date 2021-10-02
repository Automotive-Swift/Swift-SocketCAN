// This file is part of Swift-SocketCAN - (C) Dr. Michael 'Mickey' Lauer <mlauer@vanille-media.de>

import CSocketCAN
import Glibc

/// CAN Frame
public struct Frame {

    let id: UInt32
    let dlc: Int
    let data: [UInt8]
    let timestamp: Double

    /// Create padded CAN frame from data. DLC is hardcoded to 8.
    init(id: UInt32, padded data: [UInt8], pad: UInt8 = 0xAA) {
        self.id = id
        var data = data
        while data.count < 8 { data.append(pad) }
        self.dlc = data.count
        self.data = data
        self.timestamp = 0
    }

    /// Create unpadded CAN frame from data. DLC is taken from length of data.
    init(id: UInt32, unpadded data: [UInt8]) {
        self.id = id
        self.dlc = data.count
        self.data = data
        self.timestamp = 0
    }

    /// Create CAN frame from low-level structure
    fileprivate init(cm: can_frame, tv: timeval) {
        self.dlc = Int(cm.can_dlc)
        self.id = cm.can_id
        self.timestamp = Double(tv.tv_sec) + Double(tv.tv_usec) / Double(1000000)
        switch self.dlc {
            case 0: self.data = []
            case 1: self.data = [cm.data.0]
            case 2: self.data = [cm.data.0, cm.data.1]
            case 3: self.data = [cm.data.0, cm.data.1, cm.data.2]
            case 4: self.data = [cm.data.0, cm.data.1, cm.data.2, cm.data.3]
            case 5: self.data = [cm.data.0, cm.data.1, cm.data.2, cm.data.3, cm.data.4]
            case 6: self.data = [cm.data.0, cm.data.1, cm.data.2, cm.data.3, cm.data.4, cm.data.5]
            case 7: self.data = [cm.data.0, cm.data.1, cm.data.2, cm.data.3, cm.data.4, cm.data.5, cm.data.6]
            case 8: self.data = [cm.data.0, cm.data.1, cm.data.2, cm.data.3, cm.data.4, cm.data.5, cm.data.6, cm.data.7]
            default:
                preconditionFailure("CANFD frames not yet supported. TODO: Use Swift's mirror functionality to create a tuple-iterator")
        }
    }

    /// Create low-level structure from CAN frame
    var cm: can_frame {
        var cm = can_frame()
        cm.can_id = self.id
        if self.id > 0x7FF {
            /// SocketCAN needs a special flag to understand 29-bit CAN IDs
            cm.can_id |= CAN_EFF_FLAG
        }
        cm.can_dlc = UInt8(dlc)
        switch self.dlc {
            case 0: cm.data = (UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0))
            case 1: cm.data = (UInt8(self.data[0]), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0))
            case 2: cm.data = (UInt8(self.data[0]), UInt8(self.data[1]), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0))
            case 3: cm.data = (UInt8(self.data[0]), UInt8(self.data[1]), UInt8(self.data[2]), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0))
            case 4: cm.data = (UInt8(self.data[0]), UInt8(self.data[1]), UInt8(self.data[2]), UInt8(self.data[3]), UInt8(0), UInt8(0), UInt8(0), UInt8(0))
            case 5: cm.data = (UInt8(self.data[0]), UInt8(self.data[1]), UInt8(self.data[2]), UInt8(self.data[3]), UInt8(self.data[4]), UInt8(0), UInt8(0), UInt8(0))
            case 6: cm.data = (UInt8(self.data[0]), UInt8(self.data[1]), UInt8(self.data[2]), UInt8(self.data[3]), UInt8(self.data[4]), UInt8(self.data[5]), UInt8(0), UInt8(0))
            case 7: cm.data = (UInt8(self.data[0]), UInt8(self.data[1]), UInt8(self.data[2]), UInt8(self.data[3]), UInt8(self.data[4]), UInt8(self.data[5]), UInt8(self.data[6]), UInt8(0))
            case 8: cm.data = (UInt8(self.data[0]), UInt8(self.data[1]), UInt8(self.data[2]), UInt8(self.data[3]), UInt8(self.data[4]), UInt8(self.data[5]), UInt8(self.data[6]), UInt8(self.data[7]))
            default:
                preconditionFailure("CANFD frames not yet supported. TODO: Create a tuple-iterator")
        }
        return cm
    }
}

#if compiler(<5.5)
/// SocketCAN communication channel (not thread-safe)
public class SocketCAN {

    enum Error: Swift.Error {
        case canNotSupported
        case interfaceNotFound
        case interfaceNotCan
        case readError
        case writeError
        case timeout
    }

    let iface: String
    private var fd: Int32 = -1

    init(iface: String) {
        self.iface = iface
    }

    var isOpen: Bool { self.fd != -1 }

    /// Open the communication channel
    func open() throws {
        guard !self.isOpen else { return }
        let fd = socketcan_open(self.iface)
        switch fd {
            case CAN_UNSUPPORTED: throw Error.canNotSupported
            case IFACE_NOT_FOUND: throw Error.interfaceNotFound
            case IFACE_NOT_CAN: throw Error.interfaceNotCan

            default:
                self.fd = fd
        }
    }

    /// Close the communication channel
    func close() {
        guard self.isOpen else { return }
        socketcan_close(self.fd)
        self.fd = -1
    }

    /// Blocking read the next CAN frame
    func read(timeout: Int32 = 0) throws -> Frame {
        var frame = can_frame()
        var tv = timeval()
        let nBytes = socketcan_read(self.fd, &frame, &tv, timeout)
        switch nBytes {
            case TIMEOUT:
                throw Error.timeout
            case READ_ERROR:
                throw Error.readError
            default:
                let message = Frame(cm: frame, tv: tv)
                return message
        }
    }

    /// Blocking write a CAN frame
    func write(frame: Frame) throws {
        var frame = frame.cm
        let nBytes = socketcan_write(self.fd, &frame)
        guard nBytes > 0 else { throw Error.writeError }
    }

}
#else
/// Thread-safe SocketCAN actor
public actor SocketCAN {

    enum Error: Swift.Error {
        case canNotSupported
        case interfaceNotFound
        case interfaceNotCan
        case readError
        case writeError
        case timeout
    }

    nonisolated let iface: String
    private var fd: Int32 = -1

    init(iface: String) {
        self.iface = iface
    }

    var isOpen: Bool { self.fd != -1 }

    /// Open the communication channel
    func open() throws {
        guard !self.isOpen else { return }
        let fd = socketcan_open(self.iface)
        switch fd {
            case CAN_UNSUPPORTED: throw Error.canNotSupported
            case IFACE_NOT_FOUND: throw Error.interfaceNotFound
            case IFACE_NOT_CAN: throw Error.interfaceNotCan

            default:
                self.fd = fd
        }
    }

    /// Close the communication channel
    func close() {
        guard self.isOpen else { return }
        socketcan_close(self.fd)
        self.fd = -1
    }

    /// Blocking read the next CAN frame
    func read(timeout: Int32 = 0) throws -> Frame {
        var frame = can_frame()
        var tv = timeval()
        let nBytes = socketcan_read(self.fd, &frame, &tv, timeout)
        switch nBytes {
            case TIMEOUT:
                throw Error.timeout
            case READ_ERROR:
                throw Error.readError
            default:
                let message = Frame(cm: frame, tv: tv)
                return message
        }
    }

    /// Blocking write a CAN frame
    func write(frame: Frame) throws {
        var frame = frame.cm
        let nBytes = socketcan_write(self.fd, &frame)
        guard nBytes > 0 else { throw Error.writeError }
    }

    func read(timeout: Int32 = 0) async throws -> Frame {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let frame = try self.read(timeout: timeout)
                continuation.resume(returning: frame)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Asynchronous write
    func write(frame: Frame) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            do {
                try self.write(frame: frame)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
#endif