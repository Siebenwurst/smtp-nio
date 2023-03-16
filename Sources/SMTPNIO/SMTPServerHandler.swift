import NIO
import struct Foundation.Locale
import class Foundation.DateFormatter

final class SMTPServerHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = SMTPRequest
    typealias OutboundOut = SMTPResponse

    private let configuration: SMTPServer.Configuration

    private var currentEmail = Email.Pending()

    private var currentlyWaitingFor = Expect.initialMessageFromClient
    private enum Expect {
        case initialMessageFromClient
        case mailData
        case receivedFromOrMailData
        case done
    }

    public var delegate: SMTPServerDelegate?

    init(configuration: SMTPServer.Configuration) {
        self.configuration = configuration
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
            case .initialMessageFromClient, .done: break
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
        case .transferData(let email):
            Task { delegate?.received(email: email) }
        default:
            /// Should never happen
            break
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
        print(error)
        delegate?.onError(error)
    }

    func handleData(_ data: String, in context: ChannelHandlerContext) {
        print("line", data, separator: ":")
        if data.wholeMatch(of: SMTPRequest.regex.body.endOfMessage) != nil {
            if let email = currentEmail.toFinal() {
                Task { delegate?.received(email: email) }
            }
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
                if let (_, name, emailAddress) = recipient.wholeMatch(of: SMTPRequest.regex.body.from)?.output {
                    currentEmail.body.to!.append(EmailAddress(name: name.map(String.init(_:)), address: String(emailAddress)))
                }
            }
        } else if let (_, dateString) = data.wholeMatch(of: SMTPRequest.regex.body.date)?.output {
            // RFC 2822
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            currentEmail.body.date = dateFormatter.date(from: String(dateString)) ?? .now
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
