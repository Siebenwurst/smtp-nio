//
//  File.swift
//  
//
//  Created by Timo Zacherl on 16.03.23.
//

import NIO
import NIOSSL

private let sslContext = try! NIOSSLContext(configuration: TLSConfiguration.makeClientConfiguration())

final class SendEmailHandler: ChannelInboundHandler {
    typealias InboundIn = SMTPServerResponse
    typealias OutboundIn = Email.Send
    typealias OutboundOut = SMTPRequest

    enum Expect {
        case initialMessageFromServer
        case okForOurHello
        case okForStartTLS
        case tlsHandlerToBeAdded
        case okForOurAuthBegin
        case okAfterUsername
        case okAfterPassword
        case okAfterMailFrom
        case okAfterRecipient
        case okAfterDataCommand
        case okAfterMailData
        case okAfterQuit
        case nothing

        case error(Error)
    }

    private var currentlyWaitingFor = Expect.initialMessageFromServer {
        didSet {
            if case .error(let error) = self.currentlyWaitingFor {
                self.allDonePromise.fail(error)
            }
        }
    }
    private let email: Email.Send
    private let serverConfiguration: OtherServerConfiguration
    private let allDonePromise: EventLoopPromise<Void>
    private var useStartTLS: Bool {
        if case .startTLS = self.serverConfiguration.tlsConfiguration {
            return true
        } else {
            return false
        }
    }

    init(configuration: OtherServerConfiguration, email: Email.Send, allDonePromise: EventLoopPromise<Void>) {
        self.email = email
        self.allDonePromise = allDonePromise
        self.serverConfiguration = configuration
    }

    func send(context: ChannelHandlerContext, command: SMTPRequest) {
        context.writeAndFlush(self.wrapOutboundOut(command)).cascadeFailure(to: self.allDonePromise)
    }

    func sendAuthenticationStart(context: ChannelHandlerContext) {
        func goAhead() {
            self.send(context: context, command: .beginAuthentication)
            self.currentlyWaitingFor = .okForOurAuthBegin
        }

        switch self.serverConfiguration.tlsConfiguration {
        case .regularTLS, .startTLS:
            // Let's make sure we actually have a TLS handler. This code is here purely to make sure we don't have a
            // bug in the code base that would lead to sending any sensitive data without TLS (unless the user asked
            // us to do so.)
            context.channel.pipeline.handler(type: NIOSSLClientHandler.self).map { (_: NIOSSLClientHandler) in
                // we don't actually care about the NIOSSLClientHandler but we must be sure it's there.
                goAhead()
            }.whenFailure { error in
                if
                    NetworkImplementation.best == .transportServices &&
                    self.serverConfiguration.tlsConfiguration == .regularTLS
                {
                    // If we're using NIOTransportServices and regular TLS, then TLS must have been configured ahead
                    // of time, we can't check it here.
                } else {
                    preconditionFailure("serious NIOSMTP bug: TLS handler should be present in " +
                        "\(self.serverConfiguration.tlsConfiguration) but SSL handler \(error)")
                }
            }
        case .insecureNoTLS:
            // sad times here, plaintext
            goAhead()
        }
    }

    func channelInactive(context: ChannelHandlerContext) {
        self.allDonePromise.fail(ChannelError.eof)
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        self.currentlyWaitingFor = .error(error)
        self.allDonePromise.fail(error)
        context.close(promise: nil)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let result = self.unwrapInboundIn(data)
        switch result {
        case .error(let message):
            self.allDonePromise.fail(SMTPError(message: message))
            return
        case .ok:
            () // cool
        }

        switch self.currentlyWaitingFor {
        case .initialMessageFromServer:
            self.send(context: context, command: .sayHello(clientName: self.serverConfiguration.hostname))
            self.currentlyWaitingFor = .okForOurHello
        case .okForOurHello:
            if self.useStartTLS {
                self.send(context: context, command: .startTLS)
                self.currentlyWaitingFor = .okForStartTLS
            } else if serverConfiguration.authentication {
                self.sendAuthenticationStart(context: context)
            } else {
                self.currentlyWaitingFor = .okAfterPassword
            }
        case .okForStartTLS:
            self.currentlyWaitingFor = .tlsHandlerToBeAdded
            context.channel.pipeline.addHandler(
                try! NIOSSLClientHandler(
                    context: sslContext,
                    serverHostname: serverConfiguration.hostname
                ),
                position: .first
            ).whenComplete { result in
                guard case .tlsHandlerToBeAdded = self.currentlyWaitingFor else {
                    preconditionFailure("wrong state \(self.currentlyWaitingFor)")
                }

                switch result {
                case .failure(let error):
                    self.currentlyWaitingFor = .error(error)
                case .success:
                    self.sendAuthenticationStart(context: context)
                }
            }
        case .okForOurAuthBegin:
            self.send(context: context, command: .authUser(self.serverConfiguration.username))
            self.currentlyWaitingFor = .okAfterUsername
        case .okAfterUsername:
            self.send(context: context, command: .authPassword(self.serverConfiguration.password))
            self.currentlyWaitingFor = .okAfterPassword
        case .okAfterPassword:
            self.send(context: context, command: .mailFrom(self.email.sender.address))
            self.currentlyWaitingFor = .okAfterMailFrom
        case .okAfterMailFrom:
            for recipient in email.recipients {
                self.send(context: context, command: .recipient(recipient.address))
            }
            self.currentlyWaitingFor = .okAfterRecipient
        case .okAfterRecipient:
            self.send(context: context, command: .data)
            self.currentlyWaitingFor = .okAfterDataCommand
        case .okAfterDataCommand:
            self.send(context: context, command: .transferData(email))
            self.currentlyWaitingFor = .okAfterMailData
        case .okAfterMailData:
            self.send(context: context, command: .quit)
            self.currentlyWaitingFor = .okAfterQuit
        case .okAfterQuit:
            self.allDonePromise.succeed(())
            context.close(promise: nil)
            self.currentlyWaitingFor = .nothing
        case .nothing:
            () // ignoring more data whilst quit (it's odd though)
        case .error:
            fatalError("error state")
        case .tlsHandlerToBeAdded:
            fatalError("bug in NIOTS: we shouldn't hit this state here")
        }
    }
}
