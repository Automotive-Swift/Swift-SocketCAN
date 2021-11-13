import XCTest
@testable import Swift_SocketCAN

final class Swift_SocketCANTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        Task {
            let socket = SocketCAN(iface: "can0")
            try! socket.open(baudrate: 500000)

            /*
            let frame = CAN.Frame(id: 0x7e8, padded: [0x10, 0x01])
            try? await socket.write(frame: frame)
             */
    #if false
            let read1 = try! await socket.read(timeout: 5)
            //async let read2 = socket.read(timeout: 5)
            //async let read3 = socket.read(timeout: 5)
            //async let read4 = socket.read(timeout: 5)

            //try await (read1, read2, read3, read4)
            print("all read tasks finished")
            //try await print("read1: \(read1)")
            //try await print("read2: \(read2)")
            //try await print("read3: \(read3)")
            //try await print("read4: \(read4)")

        #else
            while true {
                do {
                    let frame = try socket.read(timeout: 500)
                    var str = "\(socket.iface) \(frame.timestamp): [\(frame.dlc)]"
                    for i in 0..<frame.dlc {
                        str += String(format: " %02X", frame.data[i])
                    }
                    print(str)
                } catch CAN.Error.timeout {

                } catch {
                    print("error: \(error)")
                }
            }
            #endif
        }

        RunLoop.current.run()
    }
}
