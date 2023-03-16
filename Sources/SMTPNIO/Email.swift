import struct Foundation.Date

public struct EmailAddress {
    var name: String?
    var address: String
}

public struct Email {
    var sender: String
    var recipients: [String]
    var subject: String?
    var body: Body

    public struct Body {
        var receivedFrom: String?
        var messageID: String?
        var from: EmailAddress
        var to: [EmailAddress]
        var subject: String
        var date: Date
        var mimeVersion: String?
        var xPriority: String?
        var xMailer: String?
        var contentType: String?
        var contentTransferEncoding: String?
        var content: String

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

            func toFinal() -> Body? {
                guard let from, let to, let subject, let contentType, let date else { return nil }
                return Body(
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
                    content: contentType
                )
            }
        }
    }

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
