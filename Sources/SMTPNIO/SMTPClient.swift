import NIO
import NIOTransportServices
import NIOExtras
import NIOSSL

public enum SMTPClient {
    public static func sendEmail(
        _ email: Email.Send,
        to server: OtherServerConfiguration,
        group: EventLoopGroup
    ) throws -> EventLoopFuture<Void> {
        let emailSentPromise = group.next().makePromise(of: Void.self)
        let donePromise = group.next().makePromise(of: Void.self)
        let bootstrap = try configureBootstrap(
            group: group,
            email: email,
            server: server,
            emailSentPromise: emailSentPromise
        )
        let connection = bootstrap.connect(host: server.hostname, port: server.port)

        connection.cascadeFailure(to: emailSentPromise)
        emailSentPromise.futureResult.map {
            connection.whenSuccess { $0.close(promise: nil) }
            donePromise.succeed()
        }.whenFailure { error in
            connection.whenSuccess { $0.close(promise: nil) }
            donePromise.fail(error)
        }
        return donePromise.futureResult
    }


    // MARK: - NIO/NIOTS handling

    private static func makeHandlers(
        email: Email.Send,
        server: OtherServerConfiguration,
        emailSentPromise: EventLoopPromise<Void>
    ) -> [ChannelHandler] {
        return [
            ByteToMessageHandler(LineBasedFrameDecoder()),
            SMTPResponseDecoder(),
            MessageToByteHandler(SMTPRequestEncoder()),
            SendEmailHandler(configuration: server, email: email, allDonePromise: emailSentPromise)
        ]
    }

    private static let sslContext = try! NIOSSLContext(configuration: TLSConfiguration.makeClientConfiguration())

    private static func configureBootstrap(
        group: EventLoopGroup,
        email: Email.Send,
        server: OtherServerConfiguration,
        emailSentPromise: EventLoopPromise<Void>
    ) throws -> NIOClientTCPBootstrap {
        let hostname = server.hostname
        let bootstrap: NIOClientTCPBootstrap

        switch (NetworkImplementation.best, server.tlsConfiguration) {
        case (.transportServices, .regularTLS), (.transportServices, .insecureNoTLS):
            if #available(macOS 10.14, iOS 12, tvOS 12, watchOS 3, *) {
                bootstrap = NIOClientTCPBootstrap(NIOTSConnectionBootstrap(group: group), tls: NIOTSClientTLSProvider())
            } else {
                fatalError("Network.framework unsupported on this OS, yet it was selected as the best option.")
            }
        case (.transportServices, .startTLS):
            if #available(macOS 10.14, iOS 12, tvOS 12, watchOS 3, *) {
                bootstrap = try NIOClientTCPBootstrap(
                    NIOTSConnectionBootstrap(group: group),
                    tls: NIOSSLClientTLSProvider(context: sslContext, serverHostname: hostname)
                )
            } else {
                fatalError("Network.framework unsupported on this OS, yet it was selected as the best option.")
            }
        case (.posix, _):
            bootstrap = try NIOClientTCPBootstrap(
                ClientBootstrap(group: group),
                tls: NIOSSLClientTLSProvider(context: sslContext, serverHostname: hostname)
            )
        }

        switch server.tlsConfiguration {
        case .regularTLS:
            bootstrap.enableTLS()
        case .insecureNoTLS, .startTLS:
            () // no TLS to start with
        }

        return bootstrap.channelInitializer { channel in
            channel.pipeline.addHandlers(makeHandlers(email: email, server: server, emailSentPromise: emailSentPromise))
        }
    }
}
