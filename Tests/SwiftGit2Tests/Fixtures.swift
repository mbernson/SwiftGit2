//
//  Fixtures.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/16/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import SwiftGit2
import ZipArchive

final class Fixtures {

    let directoryURL: URL

    // MARK: - Setup and Teardown

	init() throws {
		directoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
			.appendingPathComponent("org.libgit2.SwiftGit2")
            // Each instance of `Fixtures` gets a unique namespace
            .appendingPathComponent(UUID().uuidString)
        try setUp()
	}

    deinit {
        do {
            try tearDown()
        } catch {
            print("Warning: failed to tear down fixtures: \(error)")
        }
    }

	private func setUp() throws {
        // Create target directory for this set of fixtures
		try FileManager.default.createDirectory(at: directoryURL,
                                                withIntermediateDirectories: true, attributes: nil)
	}

	private func tearDown() throws {
		try FileManager.default.removeItem(at: directoryURL)
	}

	// MARK: - Helpers

	func repository(named name: String) throws -> Repository {
        let url = directoryURL.appendingPathComponent(name, isDirectory: true)

        // Lazily initialize the fixture repositories as they are requested
        if !FileManager.default.fileExists(atPath: url.path) {
            let zipPath = Bundle.module.path(forResource: name, ofType: "zip", inDirectory: "Fixtures")!
            SSZipArchive.unzipFile(atPath: zipPath, toDestination: directoryURL.path)
        }

        return try Repository.at(url).get()
	}

	// MARK: - The Fixtures

    func detachedHeadRepository() throws -> Repository {
        return try repository(named: "detached-head")
    }

    func simpleRepository() throws -> Repository {
        return try repository(named: "simple-repository")
    }

    func mantleRepository() throws -> Repository {
        return try repository(named: "Mantle")
    }
}
