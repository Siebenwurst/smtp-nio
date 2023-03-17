//
//  File.swift
//  
//
//  Created by Timo Zacherl on 16.03.23.
//

import NIO
import struct Foundation.Date
import struct Foundation.Data

final class SMTPRequestEncoder: MessageToByteEncoder, Sendable {
    typealias OutboundIn = SMTPRequest

    func encode(data: SMTPRequest, out: inout ByteBuffer) throws {
        switch data {
        case .sayHello(let server):
            out.writeString("EHLO \(server)")
        case .startTLS:
            out.writeString("STARTTLS")
        case .mailFrom(let from):
            out.writeString("MAIL FROM:<\(from)>")
        case .recipient(let rcpt):
            out.writeString("RCPT TO:<\(rcpt)>")
        case .data:
            out.writeString("DATA")
        case .transferData(let email):
            let date = Date()
            let dateFormatted = rfc2822DateFormatter.string(from: date)
            out.writeString("From: \(formatMIME(email.sender))\r\n")
            out.writeString("To: \(email.recipients.map(formatMIME(_:)).joined(separator: ","))\r\n")
            out.writeString("Date: \(dateFormatted)\r\n")
            out.writeString("Message-ID: <\(date.timeIntervalSince1970)\(email.sender.address.drop { $0 != "@" })>\r\n")
            out.writeString("Subject: \(email.subject)\r\n\r\n")
            out.writeString(email.body)
            out.writeString("\r\n.")
        case .quit:
            out.writeString("QUIT")
        case .beginAuthentication:
            out.writeString("AUTH LOGIN")
        case .authUser(let user):
            let userData = Data(user.utf8)
            out.writeBytes(userData.base64EncodedData())
        case .authPassword(let password):
            let passwordData = Data(password.utf8)
            out.writeBytes(passwordData.base64EncodedData())
        case .any: () // unused
        }

        out.writeString("\r\n")
    }

    func formatMIME(_ address: EmailAddress) -> String {
        if let name = address.name {
            return "\(name) <\(address.address)>"
        } else {
            return address.address
        }
    }
}
