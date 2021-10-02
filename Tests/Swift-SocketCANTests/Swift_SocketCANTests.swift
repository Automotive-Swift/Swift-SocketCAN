import XCTest
@testable import Swift_SocketCAN

final class Swift_SocketCANTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        Task {
            let socket = SocketCAN(iface: "toucan1")
            try! await socket.open()

            let frame = Frame(id: 0x18db33f1, padded: [0x10, 0x01])
            try? await socket.write(frame: frame)

            while true {
                do {
                    let frame = try await socket.read(timeout: 500)
                    var str = "\(socket.iface) \(frame.timestamp): [\(frame.dlc)]"
                    for i in 0..<frame.dlc {
                        str += String(format: " %02X", frame.data[i])
                    }
                    print(str)
                } catch SocketCAN.Error.timeout {

                } catch {
                    print("error: \(error)")
                }
            }
        }

        RunLoop.current.run()
    }
}
