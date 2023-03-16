import NIO
import NIOExtras

public final class SMTPServer {
    public struct Configuration {
        let address: SocketAddress?
        let serverName: String

        public init(address: SocketAddress? = nil, serverName: String) {
            self.address = address
            self.serverName = serverName
        }
    }

    let configuration: Configuration

    /// Starts a new SMTP server listening on the provided address.
    ///
    /// If no address is provided the server will listen on `::1:1025`.
    /// - Parameters:
    ///   - address: Socket address on which the server should listen.
    ///   - group: The event loop group used to bootstrap the server.
    /// - Returns: A future returning a newly started SMTP server.
    public static func start(
        _ configuration: Configuration,
        group: EventLoopGroup
    ) -> EventLoopFuture<SMTPServer> {
        let bootstrap = ServerBootstrap(group: group)
            // Set up the ServerChannel
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            // Initializes Child channels when a connection is accepted to our server
            .childChannelInitializer { addHandlers(to: $0, configuration: configuration) }
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
            return SMTPServer(channel: channel, configuration: configuration)
        }
    }

    /// Adds handlers to the pipeline.
    ///
    /// Handler flow on inbound/read events.
    /// ```
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
    /// ```
    private static func addHandlers(to channel: Channel, configuration: Configuration) -> EventLoopFuture<Void> {
        channel.pipeline.addHandlers([
            BackPressureHandler(),
            ByteToMessageHandler(LineBasedFrameDecoder()),
            ByteToMessageHandler(SMTPRequestDecoder()),
            MessageToByteHandler(SMTPResponseEncoder()),
            SMTPServerHandler(configuration: configuration),
        ])
    }

    private let channel: Channel

    public var closeFuture: EventLoopFuture<Void> { channel.closeFuture }

    init(channel: Channel, configuration: Configuration) {
        self.channel = channel
        self.configuration = configuration
        print("Server started and listening on \(channel.localAddress!)")
    }
}
