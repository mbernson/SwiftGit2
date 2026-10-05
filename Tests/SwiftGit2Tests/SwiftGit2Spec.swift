//
//  SwiftGit2Spec.swift
//  SwiftGit2
//

import Clibgit2
import Foundation
import SwiftGit2
import Testing

@Suite("SwiftGit2") class SwiftGit2Spec {
    @Suite("libgit2 build configuration") class BuildConfiguration: Libgit2Spec {
        private func backend(_ feature: git_feature_t) -> String? {
            git_libgit2_feature_backend(feature).map { String(cString: $0) }
        }

        @Test("should be built with the features libgit2 enables by default on Apple platforms")
        func defaultFeatures() throws {
            let features = git_libgit2_features()
            let expected = [GIT_FEATURE_THREADS, GIT_FEATURE_HTTPS, GIT_FEATURE_SSH, GIT_FEATURE_NSEC, GIT_FEATURE_I18N]
            for feature in expected {
                #expect(features & Int32(feature.rawValue) != 0, "missing \(feature)")
            }
        }

        @Test("should report the configured backends")
        func backends() throws {
            #expect(backend(GIT_FEATURE_THREADS) == "pthread")
            #expect(backend(GIT_FEATURE_NSEC) == "mtimespec")
            #expect(backend(GIT_FEATURE_COMPRESSION) == "builtin")
            #expect(backend(GIT_FEATURE_SHA1) == "commoncrypto")
        }
    }

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
