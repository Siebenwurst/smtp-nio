public struct OtherServerConfiguration {
    public enum TLSConfiguration: String, Decodable {
        case startTLS
        case regularTLS
        case insecureNoTLS
    }

    public var hostname: String
    public var port: Int
    public var authentication: Bool
    public var username: String
    public var password: String
    public var tlsConfiguration: TLSConfiguration

    /// Initializes a server configuration for sending emails to via ``SMTPClient``.
    /// - Parameters:
    ///   - hostname:
    ///   - port:
    ///   - authentication: Indicates if the server requires authentication, if no username and password will be ignored.
    ///   - username: Username (will be base64encoded), ignored if authentication is set to false.
    ///   - password: Password (will be base64encoded), ignored if authentication is set to false.
    ///   - tlsConfiguration: Indicates if TLS is used or not.
    public init(
        hostname: String,
        port: Int,
        authentication: Bool,
        username: String,
        password: String,
        tlsConfiguration: TLSConfiguration
    ) {
        self.hostname = hostname
        self.port = port
        self.authentication = authentication
        self.username = username
        self.password = password
        self.tlsConfiguration = tlsConfiguration
    }
}
