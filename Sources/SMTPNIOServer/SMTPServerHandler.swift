import NIO
import SMTPNIOCore

final class SMTPServerHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = SMTPRequest
    typealias OutboundOut = SMTPResponse

    private let configuration: SMTPServer.Configuration
    private let logger: Logger

    private var currentEmail = Email.Pending()

    private var currentlyWaitingFor = Expect.initialMessageFromClient
    private enum Expect {
        case initialMessageFromClient
        case mailData
        case receivedFromOrMailData
        case done
    }

    public var delegate: SMTPServerDelegate?

    init(configuration: SMTPServer.Configuration, logger: Logger) {
        self.configuration = configuration
        self.logger = logger
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let message = unwrapInboundIn(data)
        switch message {
        case .sayHello(let clientName):
            context.write(wrapOutboundOut(SMTPResponse(
                code: .commandComplete,
                message: "\(configuration.serverName) greets \(clientName)",
                isIntermediate: true
            )), promise: nil)
            context.write(wrapOutboundOut(SMTPResponse(
                code: .commandComplete,
                message: "HELP"
            )), promise: nil)
        case .mailFrom(let sender):
            currentEmail.sender = sender
            context.write(wrapOutboundOut(SMTPResponse(code: .commandComplete, message: "OK")), promise: nil)
        case .recipient(let recipient):
            if var currentRecipients = currentEmail.recipients {
                currentRecipients.append(recipient)
                currentEmail.recipients = currentRecipients
            } else {
                currentEmail.recipients = [recipient]
            }
            context.write(wrapOutboundOut(SMTPResponse(code: .commandComplete, message: "OK")), promise: nil)
        case .data:
            currentlyWaitingFor = .mailData
            context.write(wrapOutboundOut(SMTPResponse(
                code: .confirmMailContentTransfer,
                message: "Start mail input; end with <CRLF>.<CRLF>"
            )), promise: nil)
        case .any(let data):
            switch currentlyWaitingFor {
            case .initialMessageFromClient, .done:
                context.write(wrapOutboundOut(SMTPResponse(
                    code: .invalidCommand,
                    message: "Cannot parse command"
                )), promise: nil)
                logger.warning("Unknown data received: \(data)")
            case .mailData, .receivedFromOrMailData:
                handleData(data, in: context)
            }
        case .quit:
            context.writeAndFlush(wrapOutboundOut(SMTPResponse(
                code: .channelClosed,
                message: "OK"
            )), promise: nil)
            context.close(promise: nil)
            return
        case .transferData: () // doesn't happen, trust me
        default:
            context.write(wrapOutboundOut(SMTPResponse(
                code: .invalidCommand,
                message: "Cannot parse command"
            )), promise: nil)
            logger.warning("Unknown data received: \(data)")
            // TODO: implement tls and authentication
            // https://mailtrap.io/blog/smtp-commands-and-responses/
            // https://mailtrap.io/blog/smtp-security/
            // https://mailtrap.io/blog/smtp-auth/
//        case .startTLS:
//            <#code#>
//        case .beginAuthentication:
//            <#code#>
//        case .authUser(let user):
//            <#code#>
//        case .authPassword(let password):
//            <#code#>
        }

        context.flush()
    }

    func channelActive(context: ChannelHandlerContext) {
        context.writeAndFlush(wrapOutboundOut(SMTPResponse(
            code: .serverReady,
            message: "\(configuration.serverName) ESMTP"
        )), promise: nil)
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("An error occurred when handling a SMTP request: \(error.localizedDescription)")
        delegate?.onError(error)
        context.writeAndFlush(wrapOutboundOut(SMTPResponse(
            code: .localError,
            message: "Unhandled error occurred"
        )), promise: nil)
    }

    func handleData(_ data: String, in context: ChannelHandlerContext) {
        logger.trace("Line received: \(data)")
        if data.wholeMatch(of: SMTPRequest.regex.body.endOfMessage) != nil {
            if let email = currentEmail.toFinal() {
                Task { delegate?.received(email: email) }
            }
            currentEmail = Email.Pending()
            currentlyWaitingFor = .done
            context.write(wrapOutboundOut(SMTPResponse(
                code: .commandComplete,
                message: "Received"
            )), promise: nil)
        } else if let (_, sender) = data.wholeMatch(of: SMTPRequest.regex.body.receivedFrom)?.output {
            currentEmail.body.receivedFrom = String(sender)
            currentlyWaitingFor = .receivedFromOrMailData
        } else if currentlyWaitingFor == .receivedFromOrMailData && data.first == "\t" {
            currentEmail.body.receivedFrom = (currentEmail.body.receivedFrom ?? "") + " " + data.dropFirst()
        } else if let (_, messageID) = data.wholeMatch(of: SMTPRequest.regex.body.messageID)?.output {
            currentEmail.body.messageID = String(messageID)
        } else if let (_, subject) = data.wholeMatch(of: SMTPRequest.regex.body.subject)?.output {
            currentEmail.subject = String(subject)
            currentEmail.body.subject = String(subject)
        } else if let (_, name, emailAddress) = data.wholeMatch(of: SMTPRequest.regex.body.from)?.output {
            currentEmail.body.from = EmailAddress(name: name.map(String.init(_:)), address: String(emailAddress))
        } else if let (_, recipients) = data.wholeMatch(of: SMTPRequest.regex.body.to)?.output {
            currentEmail.body.to = []
            for recipient in recipients.split(separator: ",") {
                if let (_, name, emailAddress) = recipient.wholeMatch(of: SMTPRequest.regex.emailAddress)?.output {
                    currentEmail.body.to!.append(EmailAddress(name: name.map(String.init(_:)), address: String(emailAddress)))
                }
            }
        } else if let (_, dateString) = data.wholeMatch(of: SMTPRequest.regex.body.date)?.output {
            currentEmail.body.date = rfc2822DateFormatter.date(from: String(dateString)) ?? .init()
        } else if let (_, mimeVersion) = data.wholeMatch(of: SMTPRequest.regex.body.mimeVersion)?.output {
            currentEmail.body.mimeVersion = String(mimeVersion)
        } else if let (_, priority) = data.wholeMatch(of: SMTPRequest.regex.body.xPriority)?.output {
            currentEmail.body.xPriority = String(priority)
        } else if let (_, mailer) = data.wholeMatch(of: SMTPRequest.regex.body.xMailer)?.output {
            currentEmail.body.xMailer = String(mailer)
        } else if let (_, contentType) = data.wholeMatch(of: SMTPRequest.regex.body.contentType)?.output {
            currentEmail.body.contentType = String(contentType)
        } else if let (_, contentTransferEncoding) = data.wholeMatch(of: SMTPRequest.regex.body.contentTransferEncoding)?.output {
            currentEmail.body.contentTransferEncoding = String(contentTransferEncoding)
        } else {
            /// if it is non of the above it is most likely part of the "real" body
            if let content = currentEmail.body.content {
                currentEmail.body.content = content + "\n" + data
            } else {
                currentEmail.body.content = data
            }
        }
    }
}
