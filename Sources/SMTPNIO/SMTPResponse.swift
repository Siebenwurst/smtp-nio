struct SMTPResponse {
    var code: SMTPCode
    var message: String
    var isIntermediate: Bool = false
}

enum SMTPServerResponse {
    case ok(Int, String)
    case error(String)
}
