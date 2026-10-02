//
//  SwiftGit2Spec.swift
//  SwiftGit2
//

import Foundation
import SwiftGit2
import Testing

@Suite("SwiftGit2") class SwiftGit2Spec {
    @Suite("SwiftGit2SetSSLCertificateLocations(file:directory:)") class SetSSLCertificateLocations: Libgit2Spec {
        #if OPENSSL
        @Test("should accept the system certificate bundle when using OpenSSL") func acceptsBundle() throws {
            let bundle = URL(fileURLWithPath: "/etc/ssl/cert.pem")
            let result = SwiftGit2SetSSLCertificateLocations(file: bundle, directory: nil)
            #expect(result.error == nil)
        }

        @Test("should fail for a missing certificate bundle") func missingBundle() throws {
            let bundle = URL(fileURLWithPath: "/nonexistent/cert.pem")
            let result = SwiftGit2SetSSLCertificateLocations(file: bundle, directory: nil)
            #expect(result.error != nil)
        }
        #else
        @Test("should fail when the TLS backend does not support certificate locations") func unsupported() throws {
            let bundle = URL(fileURLWithPath: "/etc/ssl/cert.pem")
            let result = SwiftGit2SetSSLCertificateLocations(file: bundle, directory: nil)
            #expect(result.error != nil)
        }
        #endif
    }
}
