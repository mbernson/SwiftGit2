//
//  SwiftGit2.swift
//
//
//  Created by Mathijs Bernson on 01/03/2024.
//

import Foundation
import Clibgit2
import Clibgit2Shims

public func SwiftGit2Init() -> Result<Int, NSError> {
    let status = git_libgit2_init()
    if status < 0 {
        return .failure(NSError(gitError: status, pointOfFailure: "git_libgit2_init"))
    } else {
        return .success(Int(status))
    }
}

public func SwiftGit2Shutdown() -> Result<Int, NSError> {
    let status = git_libgit2_shutdown()
    if status < 0 {
        return .failure(NSError(gitError: status, pointOfFailure: "git_libgit2_shutdown"))
    } else {
        return .success(Int(status))
    }
}

public func Libgit2Version() -> String {
    var major: Int32 = 0
    var minor: Int32 = 0
    var patch: Int32 = 0
    git_libgit2_version(&major, &minor, &patch)

    let version: String = [major, minor, patch]
        .map(String.init)
        .joined(separator: ".")

    return version
}

/// Tells the SSL/TLS backend where to find trusted CA certificates: a PEM bundle file, a directory of
/// certificates, or both.
///
/// Only the OpenSSL backend (the `OpenSSL` package trait) supports this; the other backends return an error.
///
/// OpenSSL cannot use the system keychain. On macOS it reads the system bundle at `/etc/ssl/cert.pem` by default,
/// but iOS has no CA bundle on disk, so apps must ship one (for example Mozilla's bundle from https://curl.se/docs/caextract.html)
/// and call this before any HTTPS operation.
///
/// - Parameters:
///   - file: the location of a file containing several certificates concatenated together
///   - directory: the location of a directory holding several certificates, one per file.
///
/// Either parameter may be `nil`, but not both.
///
/// - Returns: a result with void or the error that occurred.
public func SwiftGit2SetSSLCertificateLocations(file: URL?, directory: URL?) -> Result<Void, NSError> {
    let status = swiftgit2_set_ssl_cert_locations(file?.path, directory?.path)
    if status < 0 {
        return .failure(NSError(gitError: status, pointOfFailure: "git_libgit2_opts"))
    } else {
        return .success(())
    }
}
