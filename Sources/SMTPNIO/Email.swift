import struct Foundation.Date

public struct EmailAddress {
    public var name: String?
    public var address: String

    public init(name: String? = nil, address: String) {
        self.name = name
        self.address = address
    }
}

/// Parsed email (received from a mail server)
public struct Email {
    public var sender: String
    public var recipients: [String]
    public var subject: String?
    public var body: Body

    /// Email payload sent to a mail server
    public struct Send {
        public var sender: EmailAddress
        public var recipients: [EmailAddress]
        public var subject: String
        public var body: String

        public init(sender: EmailAddress, recipients: [EmailAddress], subject: String, body: String) {
            self.sender = sender
            self.recipients = recipients
            self.subject = subject
            self.body = body
        }
    }

    public struct Body {
        public var receivedFrom: String?
        public var messageID: String?
        public var from: EmailAddress
        public var to: [EmailAddress]
        public var subject: String?
        public var date: Date
        public var mimeVersion: String?
        public var xPriority: String?
        public var xMailer: String?
        public var contentType: String?
        public var contentTransferEncoding: String?
        public var content: String

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
                guard let from, let to, let contentType, let date, let content else { return nil }
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
                    content: content
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
