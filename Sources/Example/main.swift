import SMTPNIO
import Foundation

func env(_ name: String) -> String? {
    ProcessInfo.processInfo.environment[name]
}

let server = try SMTPServer.start(
    SMTPServer.Configuration(address: SocketAddress(ipAddress: env("IP_ADDRESS") ?? "::1", port: 1025), serverName: "test.org"),
    group: MultiThreadedEventLoopGroup(numberOfThreads: 1)
).wait()
try server.closeFuture.wait()
print("Server closed")
