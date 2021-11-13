import XCTest
@testable import Swift_SocketCAN_ISOTP

final class ISOTPTests: XCTestCase {
    func testExample() throws {

        let isotp = ISOTP(iface: "can0")
        try! isotp.open(baudrate: 500000)
        let msg: [UInt8] = [0x3e]
        try isotp.write(requestId: 0x7e0, replyId: 0x7E8, bytes: msg)
        let data = try isotp.read()
        print("data: \(data)")
    }
}
