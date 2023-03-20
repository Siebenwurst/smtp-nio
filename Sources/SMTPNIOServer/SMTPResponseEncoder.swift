import NIO

final class SMTPResponseEncoder: MessageToByteEncoder {
    typealias OutboundIn = SMTPResponse

    func encode(data: SMTPResponse, out: inout ByteBuffer) throws {
        out.writeString(String(data.code.rawValue))
        out.writeString(data.isIntermediate ? "-" : " ")
        out.writeString(data.message)
        out.writeString("\r\n")
    }
}
