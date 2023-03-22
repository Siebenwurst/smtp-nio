import RegexBuilder
import SMTPNIOCore

extension SMTPRequest {
    enum regex {
        private static let leadingQuote = ChoiceOf { "<"; "\"" }
        private static let trailingQuote = ChoiceOf { ">"; "\"" }

        static let sayHello = Regex {
            Anchor.startOfSubject
            ChoiceOf {
                One("HELO")
                One("EHLO")
            }
            OneOrMore(.whitespace)
            Capture {
                OneOrMore(.anyOf("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-."))
            }
            Anchor.endOfSubject
        }
        .ignoresCase()

        static let startTLS = Regex {
            Anchor.startOfSubject
            One("STARTTLS")
            Anchor.endOfSubject
        }
        .ignoresCase()

        static let beginAuthentication = Regex {
            Anchor.startOfSubject
            One("AUTH LOGIN")
            Anchor.endOfSubject
        }
        .ignoresCase()

        static let mailFrom = Regex {
            Anchor.startOfSubject
            One("MAIL FROM:")
            ZeroOrMore(.whitespace)
            Self.leadingQuote
            Capture {
                OneOrMore(.any)
            }
            Self.trailingQuote
            Anchor.endOfSubject
        }
        .ignoresCase()

        static let recipient = Regex {
            Anchor.startOfSubject
            One("RCPT TO:")
            ZeroOrMore(.whitespace)
            Self.leadingQuote
            Capture {
                OneOrMore(.any)
            }
            Self.trailingQuote
            Anchor.endOfSubject
        }
        .ignoresCase()

        static let data = Regex {
            Anchor.startOfSubject
            One("DATA")
            Anchor.endOfSubject
        }
        .ignoresCase()

        static let quit = Regex {
            Anchor.startOfSubject
            One("QUIT")
            Anchor.endOfSubject
        }
        .ignoresCase()

        enum body {
            private static func leading(_ subject: String.RegexOutput) -> Regex<Regex<Substring>.RegexOutput> {
                Regex {
                    Anchor.startOfSubject
                    One(subject)
                    ZeroOrMore(.whitespace)
                }
            }

            static let receivedFrom = Regex {
                leading("Received:")
                Capture {
                    OneOrMore(.any)
                }
                Anchor.endOfSubject
            }
            .ignoresCase()

            static let messageID = Regex {
                leading("Message-ID:")
                regex.leadingQuote
                Capture {
                    OneOrMore(.any)
                }
                regex.trailingQuote
                Anchor.endOfSubject
            }
            .ignoresCase()

            static let subject = Regex {
                leading("Subject:")
                Capture {
                    OneOrMore(.any)
                }
                Anchor.endOfSubject
            }
            .ignoresCase()

            static let from = Regex {
                leading("From:")
                Optionally {
                    Capture {
                        OneOrMore(.any)
                    }
                    OneOrMore(.whitespace)
                }
                Optionally {
                    SMTPRequest.regex.leadingQuote
                }
                Capture {
                    OneOrMore(.any)
                }
                Optionally {
                    SMTPRequest.regex.trailingQuote
                }
                Anchor.endOfSubject
            }
            .ignoresCase()

            static let to = Regex {
                leading("To:")
                Capture {
                    OneOrMore(.any)
                }
                Anchor.endOfSubject
            }
            .ignoresCase()

            static let date = Regex {
                leading("Date:")
                Capture {
                    OneOrMore(.any)
                }
                Anchor.endOfSubject
            }
            .ignoresCase()

            static let mimeVersion = Regex {
                leading("MIME-Version:")
                Capture {
                    OneOrMore(.any)
                }
                Anchor.endOfSubject
            }
            .ignoresCase()

            static let xPriority = Regex {
                leading("X-Priority:")
                Capture {
                    OneOrMore(.any)
                }
                Anchor.endOfSubject
            }
            .ignoresCase()

            static let xMailer = Regex {
                leading("X-Mailer:")
                Capture {
                    OneOrMore(.any)
                }
                Anchor.endOfSubject
            }
            .ignoresCase()

            static let contentType = Regex {
                leading("Content-Type:")
                Capture {
                    OneOrMore(.any)
                }
                Anchor.endOfSubject
            }
            .ignoresCase()

            static let contentTransferEncoding = Regex {
                leading("Content-Transfer-Encoding:")
                Capture {
                    OneOrMore(.any)
                }
                Anchor.endOfSubject
            }

            static let endOfMessage = Regex {
                Anchor.startOfSubject
                One(".")
                Anchor.endOfSubject
            }
        }

        static let emailAddress = Regex {
            Anchor.startOfSubject
            Optionally {
                Capture {
                    OneOrMore(.any)
                }
                OneOrMore(.whitespace)
            }
            Optionally {
                SMTPRequest.regex.leadingQuote
            }
            Capture {
                OneOrMore(.any)
            }
            Optionally {
                SMTPRequest.regex.trailingQuote
            }
            Anchor.endOfSubject
        }
        .ignoresCase()
    }
}
