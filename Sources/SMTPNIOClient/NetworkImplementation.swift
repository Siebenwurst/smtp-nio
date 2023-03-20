public enum NetworkImplementation {
    /// POSIX sockets and NIO.
    case posix

    /// NIOTransportServices (and Network.framework).
    case transportServices

    /// Return the best implementation available for this platform, that is NIOTransportServices
    /// when it is available or POSIX and NIO otherwise.
    public static var best: NetworkImplementation {
        if #available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 6.0, *) {
            return .transportServices
        } else {
            return .posix
        }
    }
}
