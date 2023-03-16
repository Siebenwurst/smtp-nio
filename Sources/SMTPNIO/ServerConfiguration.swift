//
//  File.swift
//  
//
//  Created by Timo Zacherl on 16.03.23.
//

public struct OtherServerConfiguration {
    public enum TLSConfiguration {
        case startTLS
        case regularTLS
        case insecureNoTLS
    }

    var hostname: String
    var port: Int
    var username: String
    var password: String
    var tlsConfiguration: TLSConfiguration

    public init(hostname: String, port: Int, username: String, password: String, tlsConfiguration: TLSConfiguration) {
        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
        self.tlsConfiguration = tlsConfiguration
    }
}
