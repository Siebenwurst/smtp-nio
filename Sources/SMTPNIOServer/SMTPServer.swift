import NIO
import SMTPNIOCore
import NIOExtras
import Logging

public final class SMTPServer {
    public struct Configuration {
        let address: SocketAddress?
        let serverName: String

        public init(address: SocketAddress? = nil, serverName: String) {
            self.address = address
            self.serverName = serverName
        }
    }

    private let channel: Channel
    private let configuration: Configuration
    private let serverHandler: SMTPServerHandler
    private let logger: Logger

    public var closeFuture: EventLoopFuture<Void> { channel.closeFuture }
    private(set) var delegate: SMTPServerDelegate?

    init(
        channel: Channel,
        configuration: Configuration,
        serverHandler: SMTPServerHandler,
        logger: Logger
    ) {
        self.channel = channel
        self.configuration = configuration
        self.serverHandler = serverHandler
        self.logger = logger
        self.logger.info("Server started and listening on \(channel.localAddress!)")
    }

    public func setDelegate(_ delegate: SMTPServerDelegate?) {
        self.delegate = delegate
        self.serverHandler.delegate = delegate
    }

    /// Starts a new SMTP server listening on the provided address.
    ///
    /// If no address is provided the server will listen on `::1:1025`.
    /// - Parameters:
    ///   - address: Socket address on which the server should listen.
    ///   - group: The event loop group used to bootstrap the server.
    /// - Returns: A future returning a newly started SMTP server.
    public static func start(
        _ configuration: Configuration,
        group: EventLoopGroup,
        logger: Logger = Logger(label: "com.siebenwurst.smtpnio")
    ) -> EventLoopFuture<SMTPServer> {
        let serverHandler = SMTPServerHandler(configuration: configuration, logger: logger)
        let bootstrap = ServerBootstrap(group: group)
            // Set up the ServerChannel
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            // Initializes Child channels when a connection is accepted to our server
            .childChannelInitializer {
                addHandlers(to: $0, configuration: configuration, logger: logger)
                    .and($0.pipeline.addHandler(serverHandler))
                    .map { _ in () }
            }
            // Child channel options
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

        let promise: EventLoopFuture<Channel>
        if let address = configuration.address {
            promise = bootstrap.bind(to: address)
        } else {
            promise = bootstrap.bind(host: "::1", port: 1025)
        }

        return promise.map { channel in
            SMTPServer(
                channel: channel,
                configuration: configuration,
                serverHandler: serverHandler,
                logger: logger
            )
        }
    }

    /// Adds handlers to the pipeline.
    ///
    /// Handler flow on inbound/read events.
    /// ```
    /// FullTraceHandler
    ///         |
    ///         v
    /// BackpressureHandler
    ///         |
    ///         v
    /// LineBasedFrameDecoder
    ///         |
    ///         v
    /// SMTPRequestDecoder
    ///         |
    ///         v
    /// SMTPServerHandler
    /// ```
    ///
    /// Handler flow on outbound/write events.
    /// ```
    /// Write event dispatcher
    ///         |
    ///         v
    /// SMTPResponseEncoder
    ///         |
    ///         v
    /// BackPressureHandler
    ///         |
    ///         v
    /// FullTraceHandler
    /// ```
    private static func addHandlers(to channel: Channel, configuration: Configuration, logger: Logger) -> EventLoopFuture<Void> {
        channel.pipeline.addHandlers([
            FullTraceHandler(logger: logger),
            BackPressureHandler(),
            ByteToMessageHandler(LineBasedFrameDecoder()),
            ByteToMessageHandler(SMTPRequestDecoder()),
            MessageToByteHandler(SMTPResponseEncoder()),
        ])
    }
}
