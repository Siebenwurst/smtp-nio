import NIO
import struct Foundation.Data

final class FullTraceHandler: ChannelDuplexHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    private let logger: Logger
    private let otherConfiguration: OtherServerConfiguration?

    init(logger: Logger, configuration: OtherServerConfiguration? = nil) {
        self.logger = logger
        self.otherConfiguration = configuration
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = self.unwrapInboundIn(data)
        logger.trace("☁️ \(String(decoding: buffer.readableBytesView, as: UTF8.self))")
        context.fireChannelRead(data)
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
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
