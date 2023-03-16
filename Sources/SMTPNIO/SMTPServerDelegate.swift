public protocol SMTPServerDelegate {
    func received(email: Email)
    func onError(_ error: Error)
}

public extension SMTPServerDelegate {
    func onError(_ error: Error) {}
}
