import NIO
import struct Foundation.Data

public final class FullTraceHandler: ChannelDuplexHandler {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = ByteBuffer
    public typealias OutboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    private let logger: Logger
    private let otherConfiguration: OtherServerConfiguration?

    public init(logger: Logger, configuration: OtherServerConfiguration? = nil) {
        self.logger = logger
        self.otherConfiguration = configuration
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = self.unwrapInboundIn(data)
        logger.trace("☁️ \(String(decoding: buffer.readableBytesView, as: UTF8.self))")
        context.fireChannelRead(data)
    }

    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let buffer = self.unwrapOutboundIn(data)
        if
            let otherConfiguration,
            otherConfiguration.authentication,
            buffer.readableBytesView.starts(with: Data(otherConfiguration.password.utf8).base64EncodedData())
        {
            logger.trace("🔐 <password hidden>\r\n")
        } else {
            logger.trace("🔌 \(String(decoding: buffer.readableBytesView, as: UTF8.self))")
        }
        context.write(data, promise: promise)
    }
}
