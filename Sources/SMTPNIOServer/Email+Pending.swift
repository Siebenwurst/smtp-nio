import SMTPNIOCore
import struct Foundation.Date

extension Email {
    struct Pending {
        var sender: String?
        var recipients: [String]?
        var subject: String?
        var body = Body.Pending()

        func toFinal() -> Email? {
            guard let sender, let recipients, let body = body.toFinal() else { return nil }
            return Email(sender: sender, recipients: recipients, subject: subject, body: body)
        }
    }
}

extension Email.Body {
    struct Pending {
        var receivedFrom: String?
        var messageID: String?
        var from: EmailAddress?
        var to: [EmailAddress]?
        var subject: String?
        var date: Date?
        var mimeVersion: String?
        var xPriority: String?
        var xMailer: String?
        var contentType: String?
        var contentTransferEncoding: String?
        var content: String?

        func toFinal() -> Email.Body? {
            guard let from, let to, let contentType, let date, let content else { return nil }
            return Email.Body(
                receivedFrom: receivedFrom,
                messageID: messageID,
                from: from,
                to: to,
                subject: subject,
                date: date,
                mimeVersion: mimeVersion,
                xPriority: xPriority,
                xMailer: xMailer,
                contentType: contentType,
                contentTransferEncoding: contentTransferEncoding,
                content: content
            )
        }
    }
}
