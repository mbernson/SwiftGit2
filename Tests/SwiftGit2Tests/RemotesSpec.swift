//
//  RemotesSpec.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 1/2/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

import Foundation
import Testing
import SwiftGit2
import Clibgit2

private extension Repository {
    func withGitRemote<T>(named name: String, transform: (OpaquePointer) -> T) -> T {
        let repository = self.pointer

        var pointer: OpaquePointer? = nil
        git_remote_lookup(&pointer, repository, name)
        let result = transform(pointer!)
        git_remote_free(pointer)

        return result
    }
}

@Suite("Remote") class RemoteSpec {
    @Suite("Remote(pointer)") class Initializer: FixturesSpec {
        @Test("should initialize its properties") func initializer() throws {
            let repo = try fixtures.mantleRepository()
            let remote = repo.withGitRemote(named: "upstream") { Remote($0) }

            #expect(remote.name == "upstream")
            #expect(remote.URL == "git@github.com:Mantle/Mantle.git")
        }
    }

    @Suite("==(Remote, Remote)") class Equality: FixturesSpec {
        @Test("should be true with equal objects") func equal() throws {
            let repo = try fixtures.mantleRepository()
            let remote1 = repo.withGitRemote(named: "upstream") { Remote($0) }
            let remote2 = remote1
            #expect(remote1 == remote2)
        }

        @Test("should be false with unequal objcets") func unequal() throws {
            let repo = try fixtures.mantleRepository()
            let origin = repo.withGitRemote(named: "origin") { Remote($0) }
            let upstream = repo.withGitRemote(named: "upstream") { Remote($0) }
            #expect(origin != upstream)
        }
    }

    @Suite("Remote.hashValue") class HashValue: FixturesSpec {
        @Test("should be equal with equal objcets") func equal() throws {
            let repo = try fixtures.mantleRepository()
            let remote1 = repo.withGitRemote(named: "upstream") { Remote($0) }
            let remote2 = remote1
            #expect(remote1.hashValue == remote2.hashValue)
        }
    }
}
