//
//  File.swift
//  
//
//  Created by Timo Zacherl on 16.03.23.
//

public struct OtherServerConfiguration {
    public enum TLSConfiguration: String {
        case startTLS
        case regularTLS
        case insecureNoTLS
    }

    var hostname: String
    var port: Int
    var authentication: Bool
    var username: String
    var password: String
    var tlsConfiguration: TLSConfiguration

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
