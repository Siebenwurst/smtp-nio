import Foundation
import SMTPNIOCore
import NIO

final class SMTPRequestDecoder: ByteToMessageDecoder {
    typealias InboundOut = SMTPRequest
    
    func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        guard let command = buffer.readString(length: buffer.readableBytes) else {
            return .continue
        }
        
        if let match = command.firstMatch(of: SMTPRequest.regex.sayHello) {
            let (_, clientName) = match.output
            context.fireChannelRead(wrapInboundOut(.sayHello(clientName: String(clientName))))
        } else if command.wholeMatch(of: SMTPRequest.regex.startTLS) != nil {
            context.fireChannelRead(wrapInboundOut(.startTLS))
        } else if command.wholeMatch(of: SMTPRequest.regex.beginAuthentication) != nil {
            context.fireChannelRead(wrapInboundOut(.beginAuthentication))
        } else if let match = command.firstMatch(of: SMTPRequest.regex.mailFrom) {
            let (_, emailAddress) = match.output
            context.fireChannelRead(wrapInboundOut(.mailFrom(String(emailAddress))))
        } else if let match = command.firstMatch(of: SMTPRequest.regex.recipient) {
            let (_, recipient) = match.output
            context.fireChannelRead(wrapInboundOut(.recipient(String(recipient))))
        } else if command.wholeMatch(of: SMTPRequest.regex.data) != nil {
            context.fireChannelRead(wrapInboundOut(.data))
        } else if command.wholeMatch(of: SMTPRequest.regex.quit) != nil {
            context.fireChannelRead(wrapInboundOut(.quit))
        } else {
            context.fireChannelRead(wrapInboundOut(.any(command)))
        }
        
        return .needMoreData
    }
}

