public enum SMTPRequest {
    case sayHello(clientName: String)
    case startTLS
    case beginAuthentication
    case authUser(String)
    case authPassword(String)
    case mailFrom(String)
    case recipient(String)
    case data
    case transferData(Email.Send)
    case quit
    /// Is most likely ``authUser(_:)``, ``authPassword(_:)`` or ``transferData(_:)``, depending on the current context.
    ///
    /// But might be anything that couldn't be decoded.
    case any(String)
}
