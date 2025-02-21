//
//  RepositorySpec.swift
//  RepositorySpec
//
//  Created by Matt Diephouse on 11/7/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation
import Testing
import SwiftGit2

// swiftlint:disable cyclomatic_complexity

@Suite("Repository") class RepositorySpec {
    @Suite("Repository.Type.at(_:)") class At: FixturesSpec {
        @Test("should work if the repo exists") func exists() throws {
            let repo = try fixtures.simpleRepository()
            #expect(repo.directoryURL != nil)
        }

        @Test("should fail if the repo doesn't exist") func notExists() {
            let url = URL(fileURLWithPath: "blah")
            let result = Repository.at(url)
            #expect(result.error?.domain == libGit2ErrorDomain)
            #expect(result.error?.localizedDescription.starts(with: "failed to resolve path") == true)
        }
    }

    @Suite("Repository.Type.isValid(url:)") class IsValid: FixturesSpec {
        @Test("should return true if the repo exists") func exists() throws {
            let repositoryURL = try #require(fixtures.simpleRepository().directoryURL,
                "Fixture setup broken: Repository does not exist")

            let result = Repository.isValid(url: repositoryURL)

            #expect(result.error == nil)

            let isValid = try result.get()
            #expect(isValid == true)
        }

        @Test("should return false if the directory does not contain a repo") func notExists() throws {
            let tmpURL = URL(fileURLWithPath: "/dev/null")
            let result = Repository.isValid(url: tmpURL)

            #expect(result.error == nil)

            let isValid = try result.get()
            #expect(isValid == false)
        }

        @Test("should return error if .git is not readable") func notReadable() throws {
            let localURL = temporaryURL(forPurpose: "git-isValid-unreadable").appendingPathComponent(".git")
            let nonReadablePermissions: [FileAttributeKey: Any] = [.posixPermissions: 0o077]
            try FileManager.default.createDirectory(
                at: localURL,
                withIntermediateDirectories: true,
                attributes: nonReadablePermissions)
            let result = Repository.isValid(url: localURL)

            #expect(result.value == nil)
            #expect(result.error != nil)
        }
    }

    @Suite("Repository.Type.create(at:)") class Create: FixturesSpec {
        @Test("should create a new repo at the specified location") func success() throws {
            let localURL = temporaryURL(forPurpose: "local-create")
            let result = Repository.create(at: localURL)

            #expect(result.error == nil)

            let clonedRepo = try result.get()
            #expect(clonedRepo.directoryURL != nil)
        }
    }

    @Suite("Repository.Type.clone(from:to:)") class Clone: FixturesSpec {
        @Test("should handle local clones") func localClone() throws {
            let remoteRepo = try fixtures.simpleRepository()
            let localURL = temporaryURL(forPurpose: "local-clone")
            let result = Repository.clone(from: try #require(remoteRepo.directoryURL), to: localURL, localClone: true)

            #expect(result.error == nil)

            let clonedRepo = try result.get()
            #expect(clonedRepo.directoryURL != nil)
        }

        @Test("should handle bare clones") func bareClone() throws {
            let remoteRepo = try fixtures.simpleRepository()
            let localURL = temporaryURL(forPurpose: "bare-clone")
            let result = Repository.clone(from: remoteRepo.directoryURL!, to: localURL, localClone: true, bare: true)

            #expect(result.error == nil)

            let clonedRepo = try result.get()
            #expect(clonedRepo.directoryURL == nil)
        }

        @Test("should have set a valid remote url") func validRemoteURL() throws {
            let remoteRepo = try fixtures.simpleRepository()
            let localURL = temporaryURL(forPurpose: "valid-remote-clone")
            let cloneResult = Repository.clone(from: remoteRepo.directoryURL!, to: localURL, localClone: true)

            #expect(cloneResult.error == nil)

            let clonedRepo = try cloneResult.get()
            let remoteResult = clonedRepo.remote(named: "origin")
            #expect(remoteResult.error == nil)

            let remote = try remoteResult.get()
            #expect(remote.URL == remoteRepo.directoryURL?.absoluteString)
        }

        @Test("should be able to clone a remote repository") func cloneRemoteRepository() throws {
            let remoteRepoURL = try #require(URL(string: "https://github.com/libgit2/TestGitRepository.git"))
            let localURL = temporaryURL(forPurpose: "public-remote-clone")
            let cloneResult = Repository.clone(from: remoteRepoURL, to: localURL)

            #expect(cloneResult.error == nil)

            let clonedRepo = try cloneResult.get()
            let remoteResult = clonedRepo.remote(named: "origin")
            #expect(remoteResult.error == nil)

            let remote = try remoteResult.get()
            #expect(remote.URL == remoteRepoURL.absoluteString)
        }

//        let env = ProcessInfo.processInfo.environment
//
//        if let privateRepo = env["SG2TestPrivateRepo"],
//           let gitUsername = env["SG2TestUsername"],
//           let publicKey = env["SG2TestPublicKey"],
//           let privateKey = env["SG2TestPrivateKey"],
//           let passphrase = env["SG2TestPassphrase"] {
//
//            @Test("should be able to clone a remote repository requiring credentials") {
//                let remoteRepoURL = URL(string: privateRepo)
//                let localURL = temporaryURL(forPurpose: "private-remote-clone")
//                let credentials = Credentials.sshMemory(username: gitUsername,
//                                                        publicKey: publicKey,
//                                                        privateKey: privateKey,
//                                                        passphrase: passphrase)
//
//                let cloneResult = Repository.clone(from: remoteRepoURL!, to: localURL, credentials: credentials)
//
//                #expect(cloneResult.error == nil)
//
//                if case .success(let clonedRepo) = cloneResult {
//                    let remoteResult = clonedRepo.remote(named: "origin")
//                    #expect(remoteResult.error == nil)
//
//                    if case .success(let remote) = remoteResult {
//                        #expect(remote.URL == remoteRepoURL?.absoluteString)
//                    }
//                }
//            }
//        }
    }

    @Suite("Repository.blob(_:)") class BlobSpec: FixturesSpec {
        @Test("should return the commit if it exists") func exists() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba"))

            let result = repo.blob(oid)
            #expect(result.map { $0.oid }.value == oid)
        }

        @Test("should error if the blob doesn't exist") func notExists() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))

            let result = repo.blob(oid)
            #expect(result.error?.domain == libGit2ErrorDomain)
        }

        @Test("should error if the oid doesn't point to a blob") func notABlob() throws {
            let repo = try fixtures.simpleRepository()
            // This is a tree in the repository
            let oid = try #require(OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc"))

            let result = repo.blob(oid)
            #expect(result.error != nil)
        }
    }

    @Suite("Repository.commit(_:)") class CommitSpec: FixturesSpec {
        @Test("should return the commit if it exists") func exists() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))

            let result = repo.commit(oid)
            #expect(result.map { $0.oid }.value == oid)
        }

        @Test("should error if the commit doesn't exist") func notExists() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))

            let result = repo.commit(oid)
            #expect(result.error?.domain == libGit2ErrorDomain)
        }

        @Test("should error if the oid doesn't point to a commit") func notACommit() throws {
            let repo = try fixtures.simpleRepository()
            // This is a tree in the repository
            let oid = try #require(OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc"))

            let result = repo.commit(oid)
            #expect(result.error?.domain == libGit2ErrorDomain)
        }
    }

    @Suite("Repository.tag(_:)") class TagSpec: FixturesSpec {
        @Test("should return the tag if it exists") func exists() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "57943b8ee00348180ceeedc960451562750f6d33"))

            let result = repo.tag(oid)
            #expect(result.map { $0.oid }.value == oid)
        }

        @Test("should error if the tag doesn't exist") func notExists() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))

            let result = repo.tag(oid)
            #expect(result.error?.domain == libGit2ErrorDomain)
        }

        @Test("should error if the oid doesn't point to a tag") func notATag() throws {
            let repo = try fixtures.simpleRepository()
            // This is a commit in the repository
            let oid = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))

            let result = repo.tag(oid)
            #expect(result.error?.domain == libGit2ErrorDomain)
        }
    }

    @Suite("Repository.tree(_:)") class TreeSpec: FixturesSpec {
        @Test("should return the tree if it exists") func exists() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc"))

            let result = repo.tree(oid)
            #expect(result.map { $0.oid }.value == oid)
        }

        @Test("should error if the tree doesn't exist") func notExists() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))

            let result = repo.tree(oid)
            #expect(result.error?.domain == libGit2ErrorDomain)
        }

        @Test("should error if the oid doesn't point to a tree") func notATree() throws {
            let repo = try fixtures.simpleRepository()
            // This is a commit in the repository
            let oid = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))

            let result = repo.tree(oid)
            #expect(result.error?.domain == libGit2ErrorDomain)
        }
    }

    @Suite("Repository.object(_:)") class ObjectSpec: FixturesSpec {
        @Test("should work with a blob") func blob() throws {
            let repo   = try fixtures.simpleRepository()
            let oid    = try #require(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba"))
            let blob   = repo.blob(oid).value
            let result = repo.object(oid)
            #expect(result.map { $0 as! Blob }.value == blob)
        }

        @Test("should work with a commit") func commit() throws {
            let repo   = try fixtures.simpleRepository()
            let oid    = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))
            let commit = repo.commit(oid).value
            let result = repo.object(oid)
            #expect(result.map { $0 as! Commit }.value == commit)
        }

// TODO
//        @Test("should work with a tag") func tag() throws {
//            let repo   = try fixtures.simpleRepository()
//            let oid    = try #require(OID(string: "57943b8ee00348180ceeedc960451562750f6d33"))
//            let tag    = repo.tag(oid).value
//            let result = repo.object(oid)
//            #expect(result.map { $0 as! Tag }.value == tag)
//        }

        @Test("should work with a tree") func tree() throws {
            let repo   = try fixtures.simpleRepository()
            let oid    = try #require(OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc"))
            let tree   = repo.tree(oid).value
            let result = repo.object(oid)
            #expect(result.map { $0 as! Tree }.value == tree)
        }

        @Test("should error if there's no object with that oid") func nonExisting() throws {
            let repo   = try fixtures.simpleRepository()
            let oid    = try #require(OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))
            let result = repo.object(oid)
            #expect(result.error?.domain == libGit2ErrorDomain)
        }
    }

    @Suite("Repository.object(from: PointerTo)") class PointerToSpec: FixturesSpec {
        @Test("should work with commits") func commit() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))

            let pointer = PointerTo<Commit>(oid)
            let commit = try #require(repo.commit(oid).value)
            #expect(repo.object(from: pointer).value == commit)
        }

        @Test("should work with trees") func tree() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc"))

            let pointer = PointerTo<Tree>(oid)
            let tree = try #require(repo.tree(oid).value)
            #expect(repo.object(from: pointer).value == tree)
        }

        @Test("should work with blobs") func blob() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba"))

            let pointer = PointerTo<Blob>(oid)
            let blob = try #require(repo.blob(oid).value)
            #expect(repo.object(from: pointer).value == blob)
        }

// TODO
//        @Test("should work with tags") func tag() throws {
//            let repo = try fixtures.simpleRepository()
//            let oid = try #require(OID(string: "57943b8ee00348180ceeedc960451562750f6d33"))
//
//            let pointer = PointerTo<Tag>(oid)
//            let tag = try #require(repo.tag(oid).value)
//            #expect(repo.object(from: pointer).value == tag)
//        }
    }

    @Suite("Repository.object(from: Pointer)") class FromPointer: FixturesSpec {
        @Test("should work with commits") func commit() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))

            let pointer = Pointer.commit(oid)
            let commit = try #require(repo.commit(oid).value)
            let result = repo.object(from: pointer).map { $0 as! Commit }
            #expect(result.value == commit)
        }

        @Test("should work with trees") func tree() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc"))

            let pointer = Pointer.tree(oid)
            let tree = try #require(repo.tree(oid).value)
            let result = repo.object(from: pointer).map { $0 as! Tree }
            #expect(result.value == tree)
        }

        @Test("should work with blobs") func blob() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba"))

            let pointer = Pointer.blob(oid)
            let blob = try #require(repo.blob(oid).value)
            let result = repo.object(from: pointer).map { $0 as! Blob }
            #expect(result.value == blob)
        }

// TODO
//        @Test("should work with tags") func tag() throws {
//            let repo = try fixtures.simpleRepository()
//            let oid = try #require(OID(string: "57943b8ee00348180ceeedc960451562750f6d33"))
//
//            let pointer = Pointer.tag(oid)
//            let tag = try #require(repo.tag(oid).value)
//            let result = repo.object(from: pointer).map { $0 as! Tag }
//            #expect(result.value == tag)
//        }
    }

    @Suite("Repository.allRemotes()") class AllRemotes: FixturesSpec {
        @Test("should return an empty list if there are no remotes") func empty() throws {
            let repo = try fixtures.simpleRepository()
            let result = repo.allRemotes()
            #expect(result.value == [])
        }

        @Test("should return all the remotes") func all() throws {
            let repo = try fixtures.mantleRepository()
            let remotes = repo.allRemotes()
            let names = remotes.map { $0.map { $0.name } }
            #expect(remotes.map { $0.count }.value == 2)
            #expect(names.value == ["origin", "upstream"])
        }
    }

    @Suite("Repository.remote(named:)") class NamedRemote: FixturesSpec {
        @Test("should return the remote if it exists") func exists() throws {
            let repo = try fixtures.mantleRepository()
            let result = repo.remote(named: "upstream")
            #expect(result.map { $0.name }.value == "upstream")
        }

        @Test("should error if the remote doesn't exist") func notExists() throws {
            let repo = try fixtures.simpleRepository()
            let result = repo.remote(named: "nonexistent")
            #expect(result.error?.domain == libGit2ErrorDomain)
        }
    }

    @Suite("Repository.reference(named:)") class NamedReference: FixturesSpec {
        @Test("should return a local branch if it exists") func localBranch() throws {
            let name = "refs/heads/master"
            let result = try fixtures.simpleRepository().reference(named: name)
            #expect(result.map { $0.longName }.value == name)
            #expect(result.value as? Branch != nil)
        }

        @Test("should return a remote branch if it exists") func remoteBranch() throws {
            let name = "refs/remotes/upstream/master"
            let result = try fixtures.mantleRepository().reference(named: name)
            #expect(result.map { $0.longName }.value == name)
            #expect(result.value as? Branch != nil)
        }

        @Test("should return a tag if it exists") func tag() throws {
            let name = "refs/tags/tag-2"
            let result = try fixtures.simpleRepository().reference(named: name)
            #expect(result.value?.longName == name)
            #expect(result.value as? TagReference != nil)
        }

        @Test("should return the reference if it exists") func reference() throws {
            let name = "refs/other-ref"
            let result = try fixtures.simpleRepository().reference(named: name)
            #expect(result.value?.longName == name)
        }

        @Test("should error if the reference doesn't exist") func notExists() throws {
            let result = try fixtures.simpleRepository().reference(named: "refs/heads/nonexistent")
            #expect(result.error?.domain == libGit2ErrorDomain)
        }
    }

    @Suite("Repository.localBranches()") class LocalBranches: FixturesSpec {
        @Test("should return all the local branches") func localBranches() throws {
            let repo = try fixtures.simpleRepository()
            let expected = [
                try #require(repo.localBranch(named: "another-branch").value),
                try #require(repo.localBranch(named: "master").value),
                try #require(repo.localBranch(named: "yet-another-branch").value),
            ]
            #expect(repo.localBranches().value == expected)
        }
    }

    @Suite("Repository.remoteBranches()") class RemoteBranches: FixturesSpec {
        @Test("should return all the remote branches") func remoteBranches() throws {
            let repo = try fixtures.mantleRepository()
            let expectedNames = [
                "origin/2.0-development",
                "origin/HEAD",
                "origin/bump-config",
                "origin/bump-xcconfigs",
                "origin/github-reversible-transformer",
                "origin/master",
                "origin/mtlmanagedobject",
                "origin/reversible-transformer",
                "origin/subclassing-notes",
                "upstream/2.0-development",
                "upstream/bump-config",
                "upstream/bump-xcconfigs",
                "upstream/github-reversible-transformer",
                "upstream/master",
                "upstream/mtlmanagedobject",
                "upstream/reversible-transformer",
                "upstream/subclassing-notes",
            ]
            let expected = try expectedNames.map { try #require(repo.remoteBranch(named: $0).value) }
            let remoteBranches = try #require(repo.remoteBranches().value)
            let actual = remoteBranches.sorted {
                return $0.longName.lexicographicallyPrecedes($1.longName)
            }
            #expect(actual == expected)
            #expect(actual.map { $0.name } == expectedNames)
        }
    }

    @Suite("Repository.localBranch(named:)") class LocalBranch: FixturesSpec {
        @Test("should return the branch if it exists") func exists() throws {
            let result = try fixtures.simpleRepository().localBranch(named: "master")
            #expect(result.value?.longName == "refs/heads/master")
        }

        @Test("should error if the branch doesn't exists") func notExists() throws {
            let result = try fixtures.simpleRepository().localBranch(named: "nonexistent")
            #expect(result.error?.domain == libGit2ErrorDomain)
        }
    }

    @Suite("Repository.remoteBranch(named:)") class RemoteBranch: FixturesSpec {
        @Test("should return the branch if it exists") func exists() throws {
            let result = try fixtures.mantleRepository().remoteBranch(named: "upstream/master")
            #expect(result.value?.longName == "refs/remotes/upstream/master")
        }

        @Test("should error if the branch doesn't exists") func notExists() throws {
            let result = try fixtures.simpleRepository().remoteBranch(named: "origin/nonexistent")
            #expect(result.error?.domain == libGit2ErrorDomain)
        }
    }

    @Suite("Repository.fetch(_:)") class Fetch: FixturesSpec {
        @Test("should fetch the data") func fetch() throws {
            let repo = try fixtures.mantleRepository()
            let remote = try #require(repo.remote(named: "origin").value)
            #expect(repo.fetch(remote).value != nil)
        }
    }

    @Suite("Repository.allTags()") class AllTags: FixturesSpec {
        @Test("should return all the tags") func allTags() throws {
            let repo = try fixtures.simpleRepository()
            let expected = [
                try #require(repo.tag(named: "tag-1").value),
                try #require(repo.tag(named: "tag-2").value),
            ]
            #expect(repo.allTags().value == expected)
        }
    }

    @Suite("Repository.tag(named:)") class NamedTag: FixturesSpec {
        @Test("should return the tag if it exists") func exists() throws {
            let result = try fixtures.simpleRepository().tag(named: "tag-2")
            #expect(result.value?.longName == "refs/tags/tag-2")
        }

        @Test("should error if the branch doesn't exists") func notExists() throws {
            let result = try fixtures.simpleRepository().tag(named: "nonexistent")
            #expect(result.error?.domain == libGit2ErrorDomain)
        }
    }

    @Suite("Repository.HEAD()") class Head: FixturesSpec {
        @Test("should work when on a branch") func onBranch() throws {
            let result = try fixtures.simpleRepository().HEAD()
            #expect(result.value?.longName == "refs/heads/master")
            #expect(result.value?.shortName == "master")
            #expect(result.value as? Branch != nil)
        }

        @Test("should work when on a detached HEAD") func detached() throws {
            let result = try fixtures.detachedHeadRepository().HEAD()
            #expect(result.value?.longName == "HEAD")
            #expect(result.value?.shortName == nil)
            let expectedOID = try #require(OID(string: "315b3f344221db91ddc54b269f3c9af422da0f2e"))
            #expect(result.value?.oid == expectedOID)
            #expect(result.value as? Reference != nil)
        }
    }

    @Suite("Repository.setHEAD(OID)") class SetHeadToOID: FixturesSpec {
        @Test("should set HEAD to the OID") func setHeadToOID() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "315b3f344221db91ddc54b269f3c9af422da0f2e"))
            #expect(repo.HEAD().value?.shortName == "master")

            #expect(repo.setHEAD(oid).error == nil)
            let HEAD = repo.HEAD().value
            #expect(HEAD?.longName == "HEAD")
            #expect(HEAD?.oid == oid)

            let branch = try #require(repo.localBranch(named: "master").value)
            #expect(repo.setHEAD(branch).error == nil)
            #expect(repo.HEAD().value?.shortName == "master")
        }
    }

    @Suite("Repository.setHEAD(ReferenceType)") class SetHeadToReferenceType: FixturesSpec {
        @Test("should set HEAD to a branch") func setHeadToBranch() throws {
            let repo = try fixtures.detachedHeadRepository()
            let oid = try #require(repo.HEAD().value?.oid)
            #expect(repo.HEAD().value?.longName == "HEAD")

            let branch = try #require(repo.localBranch(named: "another-branch").value)
            #expect(repo.setHEAD(branch).error == nil)
            #expect(repo.HEAD().value?.shortName == branch.name)

            #expect(repo.setHEAD(oid).error == nil)
            #expect(repo.HEAD().value?.longName == "HEAD")
        }
    }

    @Suite("Repository.checkout()") class Checkout {
        // We're not really equipped to test this yet. :(
    }

    @Suite("Repository.checkout(OID)") class CheckoutOID: FixturesSpec {
        @Test("should set HEAD") func setHEAD() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "315b3f344221db91ddc54b269f3c9af422da0f2e"))
            #expect(repo.HEAD().value?.shortName == "master")

            #expect(repo.checkout(oid, strategy: CheckoutStrategy.None).error == nil)
            let HEAD = repo.HEAD().value
            #expect(HEAD?.longName == "HEAD")
            #expect(HEAD?.oid == oid)

            let branch = try #require(repo.localBranch(named: "master").value)
            #expect(repo.checkout(branch, strategy: CheckoutStrategy.None).error == nil)
            #expect(repo.HEAD().value?.shortName == "master")
        }

        @Test("should call block on progress") func progressCallback() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "315b3f344221db91ddc54b269f3c9af422da0f2e"))
            #expect(repo.HEAD().value?.shortName == "master")

            let result = repo.checkout(oid, strategy: .None, progress: { (_, completedSteps, totalSteps) -> Void in
                #expect(completedSteps <= totalSteps)
            })
            #expect(result.error == nil)

            let HEAD = repo.HEAD().value
            #expect(HEAD?.longName == "HEAD")
            #expect(HEAD?.oid == oid)
        }
    }

    @Suite("Repository.checkout(ReferenceType)") class CheckoutReferenceType: FixturesSpec {
        @Test("should set HEAD") func setHEAD() throws {
            let repo = try fixtures.detachedHeadRepository()
            let oid = try #require(repo.HEAD().value?.oid)
            #expect(repo.HEAD().value?.longName == "HEAD")

            let branch = try #require(repo.localBranch(named: "another-branch").value)
            #expect(repo.checkout(branch, strategy: CheckoutStrategy.None).error == nil)
            #expect(repo.HEAD().value?.shortName == branch.name)

            #expect(repo.checkout(oid, strategy: CheckoutStrategy.None).error == nil)
            #expect(repo.HEAD().value?.longName == "HEAD")
        }
    }

    @Suite("Repository.allCommits(in:)") class AllCommits: FixturesSpec {
        @Test("should return all (9) commits") func allCommits() throws {
            let repo = try fixtures.simpleRepository()
            let branches = try #require(repo.localBranches().value)
            let expectedCount = 9
            let expectedMessages: [String] = [
                "List branches in README\n",
                "Create a README\n",
                "Merge branch 'alphabetize'\n",
                "Alphabetize branches\n",
                "List new branches\n",
                "List branches in README\n",
                "Create a README\n",
                "List branches in README\n",
                "Create a README\n",
            ]
            let commitMessages: [String] = branches.flatMap { branch in
                repo.commits(in: branch).compactMap { commit in
                    commit.value?.message
                }
            }
            #expect(commitMessages.count == expectedCount)
            #expect(commitMessages == expectedMessages)
        }
    }

    @Suite("Repository.add") class Add: FixturesSpec {
        @Test("Should add the modification under a path") func addPath() throws {
            let repo = try fixtures.simpleRepository()
            let branch = try #require(repo.localBranch(named: "master").value)
            #expect(repo.checkout(branch, strategy: CheckoutStrategy.None).error == nil)

            // make a change to README
            let readmeURL = try #require(repo.directoryURL?.appendingPathComponent("README.md"))
            let data = try #require("different".data(using: .utf8))
            try data.write(to: readmeURL)

            let status = try #require(repo.status().value)
            #expect(status.count == 1)
            #expect(status.first?.status == .workTreeModified)

            #expect(repo.add(path: "README.md").error == nil)

            let newStatus = try #require(repo.status().value)
            #expect(newStatus.count == 1)
            #expect(newStatus.first?.status == .indexModified)
        }

        @Test("Should add an untracked file under a path") func addUntrackedPath() throws {
            let repo = try fixtures.simpleRepository()
            let branch = try #require(repo.localBranch(named: "master").value)
            #expect(repo.checkout(branch, strategy: CheckoutStrategy.None).error == nil)

            // make a change to README
            let untrackedURL = try #require(repo.directoryURL?.appendingPathComponent("untracked"))
            let data = try #require("different".data(using: .utf8))
            try data.write(to: untrackedURL)

            #expect(repo.add(path: ".").error == nil)

            let newStatus = try #require(repo.status().value)
            #expect(newStatus.count == 1)
            #expect(newStatus.first?.status == .indexNew)
        }

        deinit {
            let repo = try? fixtures.simpleRepository()

            if let untrackedURL = repo?.directoryURL?.appendingPathComponent("untracked") {
                try? FileManager.default.removeItem(at: untrackedURL)
            }

            if let readmeURL = repo?.directoryURL?.appendingPathComponent("README.md") {
                try? FileManager.default.removeItem(at: readmeURL)
            }
        }
    }

    @Suite("Repository.commit") class RepositoryCommit: FixturesSpec {
        @Test("Should perform a simple commit with specified signature") func commit() throws {
            let repo = try fixtures.simpleRepository()
            let branch = repo.localBranch(named: "master").value!
            #expect(repo.checkout(branch, strategy: CheckoutStrategy.None).error == nil)

            // make a change to README
            let untrackedURL = try #require(repo.directoryURL?.appendingPathComponent("untrackedtest"))
            let data = try #require("different".data(using: .utf8))
            try data.write(to: untrackedURL)

            #expect(repo.add(path: ".").error == nil)

            let signature = Signature(
                name: "swiftgit2",
                email: "foobar@example.com",
                time: Date(timeIntervalSince1970: 1525200858),
                timeZone: TimeZone(secondsFromGMT: 3600)!
            )
            let message = "Test Commit"
            #expect(repo.commit(message: message, signature: signature).error == nil)
            let updatedBranch = repo.localBranch(named: "master").value!
            #expect(repo.commits(in: updatedBranch).next()?.value?.author == signature)
            #expect(repo.commits(in: updatedBranch).next()?.value?.committer == signature)
            #expect(repo.commits(in: updatedBranch).next()?.value?.message == "\(message)\n")
            #expect(repo.commits(in: updatedBranch).next()?.value?.oid.description ==
                "7d6b2d7492f29aee48022387f96dbfe996d435fe")

            // should be clean now
            let newStatus = try #require(repo.status().value)
            #expect(newStatus.count == 0)
        }
    }

    @Suite("Repository.status") class RepositoryStatus: FixturesSpec {
        @Test("Should accurately report status for repositories with no status") func noStatus() throws {
            let expectedCount = 0

            let repo = try fixtures.mantleRepository()
            let branch = try #require(repo.localBranch(named: "master").value)
            #expect(repo.checkout(branch, strategy: CheckoutStrategy.None).error == nil)

            let status = repo.status()

            #expect(status.value?.count == expectedCount)
        }

        @Test("Should accurately report status for repositories with status") func withStatus() throws {
            let expectedCount = 6
            let expectedNewFilePaths = [
                "stage-file-1",
                "stage-file-2",
                "stage-file-3",
                "stage-file-4",
                "stage-file-5",
            ]
            let expectedOldFilePaths = [
                "stage-file-1",
                "stage-file-2",
                "stage-file-3",
                "stage-file-4",
                "stage-file-5",
            ]
            let expectedUntrackedFiles = [
                "unstaged-file",
            ]

            let repoWithStatus = try fixtures.repository(named: "repository-with-status")
            let branchWithStatus = try #require(repoWithStatus.localBranch(named: "master").value)
            #expect(repoWithStatus.checkout(branchWithStatus, strategy: CheckoutStrategy.None).error == nil)

            let statuses = repoWithStatus.status().value!

            let newFilePaths: [String] = statuses.compactMap { status in
                status.headToIndex?.newFile?.path
            }
            let oldFilePaths: [String] = statuses.compactMap { status in
                status.headToIndex?.oldFile?.path
            }
            let newUntrackedFilePaths: [String] = statuses.compactMap { status in
                status.indexToWorkDir?.newFile?.path
            }

            #expect(statuses.count == expectedCount)
            #expect(newFilePaths == expectedNewFilePaths)
            #expect(oldFilePaths == expectedOldFilePaths)
            #expect(newUntrackedFilePaths == expectedUntrackedFiles)
        }
    }

    @Suite("Repository.diff") class RepositoryDiff: FixturesSpec {
        @Test("Should have accurate delta information") func deltas() throws {
            let expectedCount = 13
            let expectedNewFilePaths = [
                ".gitmodules",
                "Cartfile",
                "Cartfile.lock",
                "Cartfile.private",
                "Cartfile.resolved",
                "Carthage.checkout/Nimble",
                "Carthage.checkout/Quick",
                "Carthage.checkout/xcconfigs",
                "Carthage/Checkouts/Nimble",
                "Carthage/Checkouts/Quick",
                "Carthage/Checkouts/xcconfigs",
                "Mantle.xcodeproj/project.pbxproj",
                "Mantle.xcworkspace/contents.xcworkspacedata",
            ]
            let expectedOldFilePaths = [
                ".gitmodules",
                "Cartfile",
                "Cartfile.lock",
                "Cartfile.private",
                "Cartfile.resolved",
                "Carthage.checkout/Nimble",
                "Carthage.checkout/Quick",
                "Carthage.checkout/xcconfigs",
                "Carthage/Checkouts/Nimble",
                "Carthage/Checkouts/Quick",
                "Carthage/Checkouts/xcconfigs",
                "Mantle.xcodeproj/project.pbxproj",
                "Mantle.xcworkspace/contents.xcworkspacedata",
            ]

            let repo = try fixtures.mantleRepository()
            let branch = repo.localBranch(named: "master").value!
            #expect(repo.checkout(branch, strategy: CheckoutStrategy.None).error == nil)

            let head = repo.HEAD().value!
            let commit = repo.object(head.oid).value! as! Commit
            let diff = repo.diff(for: commit).value!

            let newFilePaths = diff.deltas.map { $0.newFile!.path }
            let oldFilePaths = diff.deltas.map { $0.oldFile!.path }

            #expect(diff.deltas.count == expectedCount)
            #expect(newFilePaths == expectedNewFilePaths)
            #expect(oldFilePaths == expectedOldFilePaths)
        }

        @Test("Should handle initial commit well") func initialCommit() throws {
            let expectedCount = 2
            let expectedNewFilePaths = [
                ".gitignore",
                "README.md",
            ]
            let expectedOldFilePaths = [
                ".gitignore",
                "README.md",
            ]

            let repo = try fixtures.mantleRepository()
            #expect(repo.checkout(try #require(OID(string: "047b931bd7f5478340cef5885a6fff713005f4d6")),
                                 strategy: CheckoutStrategy.None).error == nil)
            let head = repo.HEAD().value!
            let initalCommit = repo.object(head.oid).value! as! Commit
            let diff = repo.diff(for: initalCommit).value!

            var newFilePaths: [String] = []
            for delta in diff.deltas {
                newFilePaths.append((delta.newFile?.path)!)
            }
            var oldFilePaths: [String] = []
            for delta in diff.deltas {
                oldFilePaths.append((delta.oldFile?.path)!)
            }

            #expect(diff.deltas.count == expectedCount)
            #expect(newFilePaths == expectedNewFilePaths)
            #expect(oldFilePaths == expectedOldFilePaths)
        }

        @Test("Should handle merge commits well") func mergeCommit() throws {
            let expectedCount = 20
            let expectedNewFilePaths = [
                "Mantle.xcodeproj/project.pbxproj",
                "Mantle/MTLModel+NSCoding.m",
                "Mantle/Mantle.h",
                "Mantle/NSArray+MTLHigherOrderAdditions.h",
                "Mantle/NSArray+MTLHigherOrderAdditions.m",
                "Mantle/NSArray+MTLManipulationAdditions.m",
                "Mantle/NSDictionary+MTLHigherOrderAdditions.h",
                "Mantle/NSDictionary+MTLHigherOrderAdditions.m",
                "Mantle/NSDictionary+MTLManipulationAdditions.m",
                "Mantle/NSNotificationCenter+MTLWeakReferenceAdditions.h",
                "Mantle/NSNotificationCenter+MTLWeakReferenceAdditions.m",
                "Mantle/NSOrderedSet+MTLHigherOrderAdditions.h",
                "Mantle/NSOrderedSet+MTLHigherOrderAdditions.m",
                "Mantle/NSSet+MTLHigherOrderAdditions.h",
                "Mantle/NSSet+MTLHigherOrderAdditions.m",
                "Mantle/NSValueTransformer+MTLPredefinedTransformerAdditions.m",
                "MantleTests/MTLHigherOrderAdditionsSpec.m",
                "MantleTests/MTLNotificationCenterAdditionsSpec.m",
                "MantleTests/MTLPredefinedTransformerAdditionsSpec.m",
                "README.md",
            ]
            let expectedOldFilePaths = [
                "Mantle.xcodeproj/project.pbxproj",
                "Mantle/MTLModel+NSCoding.m",
                "Mantle/Mantle.h",
                "Mantle/NSArray+MTLHigherOrderAdditions.h",
                "Mantle/NSArray+MTLHigherOrderAdditions.m",
                "Mantle/NSArray+MTLManipulationAdditions.m",
                "Mantle/NSDictionary+MTLHigherOrderAdditions.h",
                "Mantle/NSDictionary+MTLHigherOrderAdditions.m",
                "Mantle/NSDictionary+MTLManipulationAdditions.m",
                "Mantle/NSNotificationCenter+MTLWeakReferenceAdditions.h",
                "Mantle/NSNotificationCenter+MTLWeakReferenceAdditions.m",
                "Mantle/NSOrderedSet+MTLHigherOrderAdditions.h",
                "Mantle/NSOrderedSet+MTLHigherOrderAdditions.m",
                "Mantle/NSSet+MTLHigherOrderAdditions.h",
                "Mantle/NSSet+MTLHigherOrderAdditions.m",
                "Mantle/NSValueTransformer+MTLPredefinedTransformerAdditions.m",
                "MantleTests/MTLHigherOrderAdditionsSpec.m",
                "MantleTests/MTLNotificationCenterAdditionsSpec.m",
                "MantleTests/MTLPredefinedTransformerAdditionsSpec.m",
                "README.md",
            ]

            let repo = try fixtures.mantleRepository()
            #expect(repo.checkout(try #require(OID(string: "d0d9c13da5eb5f9e8cf2a9f1f6ca3bdbe975b57d")),
                                 strategy: CheckoutStrategy.None).error == nil)
            let head = try #require(repo.HEAD().value)
            let initalCommit = try #require(repo.object(head.oid).value as? Commit)
            let diff = repo.diff(for: initalCommit).value!

            let newFilePaths: [String] = diff.deltas.compactMap { delta in
                delta.newFile?.path
            }
            let oldFilePaths: [String] = diff.deltas.compactMap { delta in
                delta.oldFile?.path
            }

            #expect(diff.deltas.count == expectedCount)
            #expect(newFilePaths == expectedNewFilePaths)
            #expect(oldFilePaths == expectedOldFilePaths)
        }
    }
}

private func temporaryURL(forPurpose purpose: String) -> URL {
    let globallyUniqueString = ProcessInfo.processInfo.globallyUniqueString
    let path = "\(NSTemporaryDirectory())\(globallyUniqueString)_\(purpose)"
    return URL(fileURLWithPath: path)
}
