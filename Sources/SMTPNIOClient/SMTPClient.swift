import NIO
import NIOTransportServices
import NIOExtras
import NIOSSL
import SMTPNIOCore
import Logging

public enum SMTPClient {
    public static func sendEmail(
        _ email: Email.Send,
        to server: OtherServerConfiguration,
        logger: Logger = Logger(label: "com.siebenwurst.smtpnio-client"),
        group: EventLoopGroup
    ) throws -> EventLoopFuture<Void> {
        let emailSentPromise = group.next().makePromise(of: Void.self)
        let donePromise = group.next().makePromise(of: Void.self)
        let bootstrap = try configureBootstrap(
            group: group,
            email: email,
            server: server,
            emailSentPromise: emailSentPromise,
            logger: logger
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
        emailSentPromise: EventLoopPromise<Void>,
        logger: Logger
    ) -> [ChannelHandler] {
        return [
            FullTraceHandler(logger: logger, configuration: server),
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
        emailSentPromise: EventLoopPromise<Void>,
        logger: Logger
    ) throws -> NIOClientTCPBootstrap {
        let hostname = server.hostname
        let bootstrap: NIOClientTCPBootstrap

        switch (NetworkImplementation.best, server.tlsConfiguration) {
        case (.transportServices, .regularTLS), (.transportServices, .insecureNoTLS):
            #if canImport(Network)
            if #available(macOS 10.14, iOS 12, tvOS 12, watchOS 3, *) {
                bootstrap = NIOClientTCPBootstrap(NIOTSConnectionBootstrap(group: group), tls: NIOTSClientTLSProvider())
            } else {
                logger.critical(".networkFramework is being used on an unsupported platform")
                fatalError("Network.framework unsupported on this OS, yet it was selected as the best option.")
            }
            #else
            logger.critical(".networkFramework is being used on an unsupported platform")
            fatalError("Network.framework unsupported on this OS, yet it was selected as the best option.")
            #endif
        case (.transportServices, .startTLS):
            #if canImport(Network)
            if #available(macOS 10.14, iOS 12, tvOS 12, watchOS 3, *) {
                bootstrap = try NIOClientTCPBootstrap(
                    NIOTSConnectionBootstrap(group: group),
                    tls: NIOSSLClientTLSProvider(context: sslContext, serverHostname: hostname)
                )
            } else {
                logger.critical(".networkFramework is being used on an unsupported platform")
                fatalError("Network.framework unsupported on this OS, yet it was selected as the best option.")
            }
            #else
            logger.critical(".networkFramework is being used on an unsupported platform")
            fatalError("Network.framework unsupported on this OS, yet it was selected as the best option.")
            #endif
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
            channel.pipeline.addHandlers(makeHandlers(
                email: email,
                server: server,
                emailSentPromise: emailSentPromise,
                logger: logger
            ))
        }
    }
}
