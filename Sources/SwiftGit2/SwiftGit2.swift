//
//  SwiftGit2.swift
//  SwiftGit2
//
//  Created by Mathijs Bernson on 01/03/2024.
//

import Clibgit2
import Clibgit2Helpers
import Foundation

/// Initialize the libgit2 library for use.
///
/// This function must be called before any other SwiftGit2 function in order to set up libgit2 global state and threading.
/// This function may be called multiple times - it will return the number of times the initialization has been called (including this one) that have not subsequently been shutdown.
public func SwiftGit2Init() -> Result<Int, NSError> {
	let initStatus = git_libgit2_init()
	if initStatus < 0 {
		return .failure(NSError(gitError: initStatus, pointOfFailure: "git_libgit2_init"))
	}

	git_opt_set_ssl_cert_locations("/etc/ssl/cert.pem", nil)
	// git_opt_set_user_agent("SwiftGit2")

	return .success(Int(initStatus))
}

/// Shutdown the libgit2 library.
///
/// Clean up the global state and threading context after calling it as many times as SwiftGit2Init() was called - it will return the number of remainining initializations that have not been shutdown (after this one).
public func SwiftGit2Shutdown() -> Result<Int, NSError> {
	let status = git_libgit2_shutdown()
	if status < 0 {
		return .failure(NSError(gitError: status, pointOfFailure: "git_libgit2_shutdown"))
	} else {
		return .success(Int(status))
	}
}

/// Return the version of the linked libgit2 library being currently used.
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
