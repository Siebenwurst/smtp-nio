struct SMTPResponse {
    var code: SMTPCode
    var message: String
    var isIntermediate: Bool = false
}
