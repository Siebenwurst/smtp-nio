/// SMTP Codes.
///
/// **Command - Response Matrix**
///
/// | Command                                                         | Positive response                          | Negative response                                                                      |
/// | ---------------------------------------------------- | -------------------------------------- | ----------------------------------------------------------------------- |
/// | SMTP handshake (establishing a connection) | 220                                                 | 554                                                                                              |
/// | STARTTLS                                                        | 220                                                 | 454                                                                                              |
/// | EHLO or HELO                                                 | 250                                                 | 502 (response to EHLO for old-time servers); 504; 550             |
/// | AUTH                                                                | 235; 334                                         | 530; 535; 538                                                                              |
/// | MAIL FROM                                                      | 250                                                 | 451; 452; 455; 503; 550; 552 ;553; 555                                      |
/// | RCPT TO                                                           |  250; 251                                       | 450; 451; 452; 455; 503; 550; 551; 552; 553; 555                       |
/// | DATA                                                                 | 250; 354 (intermediate response)  | 450; 451; 452; 503; 550 (rejection for policy reasons); 552; 554 |
/// | RSET                                                                 | 250                                                | –                                                                                                   |
/// | VRFY                                                                 | 250; 251; 252                                | 502; 504; 550; 551; 553                                                               |
/// | EXPN                                                                 | 250; 252                                        | 502; 504; 550                                                                               |
/// | HELP                                                                 | 211; 214                                        | 502; 504                                                                                       |
/// | NOOP                                                                | 250                                                | –                                                                                                   |
/// | QUIT                                                                  | 221                                                | –                                                                                                   |
enum SMTPCode: Int {
    /// Server connection error (wrong server name or connection port)
    case serverConnectionError = 101
    /// System status (response to HELP)
    case systemStatus = 211
    /// Help message (response to HELP)
    case helpMessage = 214
    /// The server is ready (response to the client’s attempt to establish a TCP connection)
    case serverReady = 220
    /// The server closes the transmission channel
    case channelClosed = 221
    /// Authentication successful (response to AUTH)
    case authenticationSuccessful = 235
    /// The requested command is completed. As a rule, the code is followed by OK
    case commandComplete = 250
    /// User is not local, but the server will forward the message to <forward-path>
    case forwardMessageForNonLocalUser = 251
    /// The server cannot verify the user (response to VRFY). The message will be accepted and attempted for delivery
    case cannotVerifyUserButAttemptToDeliver = 252
    /// Response to the AUTH command when the requested security mechanism is accepted
    case acceptSecurityMechanischm = 334
    /// The server confirms mail content transfer (response to DATA). After that, the client starts sending the mail. Terminated with a period ( “.”)
    case confirmMailContentTransfer = 354
    /// The server is unavailable because it closes the transmission channel
    case serverUnavailable = 421
    /// The recipient’s mailbox has exceeded its storage limit
    case recipientsMailboxExceededStorageLimit = 422
    /// File overload (too many messages sent to a particular domain)
    case fileOverload = 431
    /// No response from the recipient’s server
    case noResponse = 441
    /// Connection dropped
    case connectionDropped = 442
    /// Internal loop has occurred
    case internalLoopOccurred = 446
    /// Mailbox unavailable (busy or temporarily blocked). Requested action aborted
    case mailboxBusyOrBlocked = 450
    /// The server aborted the command due to a local error
    case localError = 451
    /// The server aborted the command due to insufficient system storage
    case insufficientSystemStorage = 452
    /// TLS not available due to a temporary reason (response to STARTTLS)
    case tlsUnavailable = 454
    /// Parameters cannot be accommodated
    case parametersNotAccommodated = 455
    /// Mail server error due to the local spam filter
    case localSpamFilterError = 471
    /// Syntax error (also a command line may be too long). The server cannot recognize the command
    case invalidCommand = 500
    /// Syntax error in parameters or arguments
    case invalidParameterOrArgument = 501
    /// The server has not implemented the command
    case unimplementedCommand = 502
    /// Improper sequence of commands
    case improperCommandSequence = 503
    /// The server has not implemented a command parameter
    case unimplementedCommandParameter = 504
    /// Invalid email address
    case invalidEmailAddress = 510
    /// A DNS error (recheck the address of your recipients)
    case dnsError = 512
    /// The total size of your mailing exceeds the recipient server limits
    case receipientServerLimitExceeded = 523
    /// Authentication problem that mostly requires the STARTTLS command to run
    case genericAuthenticationProblem = 530
    /// Authentication failed
    case authenticationFailed = 535
    /// Encryption required for a requested authentication mechanism
    case encryptionRequiredForAuthenticationMechanism = 538
    /// Message rejected by spam filter
    case messageRejected = 541
    /// Mailbox is unavailable. Server aborted the command because the mailbox was not found or for policy reasons. Alternatively: Authentication is required for relay
    case mailboxUnavailable = 550
    /// User not local. The <forward-path> will be specified
    case userNotLocal = 551
    /// The server aborted the command because the mailbox is full
    case commandAborted = 552
    /// Syntactically incorrect mail address
    case incorrectMailAddressSyntax = 553
    /// The transaction failed due to an unknown error or No SMTP service here as a response to the client’s attempts to establish a connection
    case unknownError = 554
    /// Parameters not recognized/ not implemented (response to MAIL FROM or RCPT TO)
    case notRecognizableParameters = 555
}
