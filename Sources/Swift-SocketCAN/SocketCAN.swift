// This file is part of Swift-SocketCAN - (C) Dr. Michael 'Mickey' Lauer <mlauer@vanille-media.de>
#if !os(Linux)
#error("This package requires Linux >= 5.10")
#endif

import CSocketCAN
import Glibc
@_exported import Swift_CAN

/// CAN Frame extensions for converting between low-level and common format
extension CAN.Frame {

    /// Create CAN frame from low-level structure
    fileprivate init(cm: can_frame, tv: timeval) {
        let id = cm.can_id & 0x1fffffff // mask out any flags
        let dlc = Int(cm.can_dlc)
        let timestamp = Double(tv.tv_sec) + Double(tv.tv_usec) / Double(1000000)
        var data: [UInt8] = []
        switch dlc {
            case 0: data = []
            case 1: data = [cm.data.0]
            case 2: data = [cm.data.0, cm.data.1]
            case 3: data = [cm.data.0, cm.data.1, cm.data.2]
            case 4: data = [cm.data.0, cm.data.1, cm.data.2, cm.data.3]
            case 5: data = [cm.data.0, cm.data.1, cm.data.2, cm.data.3, cm.data.4]
            case 6: data = [cm.data.0, cm.data.1, cm.data.2, cm.data.3, cm.data.4, cm.data.5]
            case 7: data = [cm.data.0, cm.data.1, cm.data.2, cm.data.3, cm.data.4, cm.data.5, cm.data.6]
            case 8: data = [cm.data.0, cm.data.1, cm.data.2, cm.data.3, cm.data.4, cm.data.5, cm.data.6, cm.data.7]
            default:
                preconditionFailure("CANFD frames not yet supported. TODO: Use Swift's mirror functionality to create a tuple-iterator")
        }
        self.init(id: id, dlc: dlc, unpadded: data, timestamp: timestamp)
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

/// A simple SocketCAN communication channel. Blocking operations, not thread-safe.
public class SocketCAN: CAN.Interface {

    public let model: String = "Swift-SocketCAN"
    public let vendor: String = "Automotive-Swift"
    public let serialNumber: String = "1234567890"
    public var name: String { self.iface }
    public var bitrate: Int = -1

    let iface: String
    private var fd: Int32 = -1

    public init(iface: String) {
        self.iface = iface
    }

    var isOpen: Bool { self.fd != -1 }

    /// Open the communication channel
    public func open(bitrate: Int) throws {
        guard !self.isOpen else { return }
        let fd = socketcan_open(self.iface, Int32(bitrate))
        switch fd {
            case CAN_UNSUPPORTED: throw CAN.Error.canNotSupported
            case IFACE_NOT_FOUND: throw CAN.Error.interfaceNotFound
            case IFACE_NOT_CAN: throw CAN.Error.interfaceNotCan
            case IFACE_CONFIGURATION: throw CAN.Error.unsupportedConfiguration

            default:
                self.fd = fd
                self.bitrate = bitrate
        }
    }

    /// Close the communication channel
    public func close() {
        guard self.isOpen else { return }
        socketcan_close(self.fd)
        self.fd = -1
        self.bitrate = -1
    }

    /// Blocking read the next CAN frame.
    public func read(timeout: Int = 0) throws -> CAN.Frame {
        var frame = can_frame()
        var tv = timeval()
        let nBytes = socketcan_read(self.fd, &frame, &tv, Int32(timeout))
        switch nBytes {
            case TIMEOUT:
                throw CAN.Error.timeout
            case READ_ERROR:
                throw CAN.Error.readError
            default:
                let message = CAN.Frame(cm: frame, tv: tv)
                return message
        }
    }

    /// Blocking write a CAN frame.
    public func write(_ frame: CAN.Frame) throws {
        var frame = frame.cm
        let nBytes = socketcan_write(self.fd, &frame)
        guard nBytes > 0 else { throw CAN.Error.writeError }
    }
}
