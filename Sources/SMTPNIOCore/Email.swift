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

    public init(sender: String, recipients: [String], subject: String? = nil, body: Body) {
        self.sender = sender
        self.recipients = recipients
        self.subject = subject
        self.body = body
    }

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

        public init(receivedFrom: String? = nil, messageID: String? = nil, from: EmailAddress, to: [EmailAddress], subject: String? = nil, date: Date, mimeVersion: String? = nil, xPriority: String? = nil, xMailer: String? = nil, contentType: String? = nil, contentTransferEncoding: String? = nil, content: String) {
            self.receivedFrom = receivedFrom
            self.messageID = messageID
            self.from = from
            self.to = to
            self.subject = subject
            self.date = date
            self.mimeVersion = mimeVersion
            self.xPriority = xPriority
            self.xMailer = xMailer
            self.contentType = contentType
            self.contentTransferEncoding = contentTransferEncoding
            self.content = content
        }
    }
}
