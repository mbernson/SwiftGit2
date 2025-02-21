//
//  ReferencesSpec.swift
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
    func withGitReference<T>(named name: String, transform: (OpaquePointer) -> T) -> T {
        let repository = self.pointer
        
        var pointer: OpaquePointer? = nil
        git_reference_lookup(&pointer, repository, name)
        let result = transform(pointer!)
        git_reference_free(pointer)
        
        return result
    }
}

@Suite("Reference") class ReferenceSpec {
    @Suite("Reference(pointer)") class Initialization: FixturesSpec {
        @Test("should initialize its properties") func properties() throws {
            let repo = try fixtures.simpleRepository()
            let ref = repo.withGitReference(named: "refs/heads/master") { Reference($0) }
            #expect(ref.longName == "refs/heads/master")
            #expect(ref.shortName == "master")
            let expectedOID = try #require(OID(string: "c4ed03a6b7d7ce837d31d83757febbe84dd465fd"))
            #expect(ref.oid == expectedOID)
        }
    }
    
    @Suite("==(Reference, Reference)") class Equality: FixturesSpec {
        @Test("should be true with equal references") func equal() throws {
            let repo = try fixtures.simpleRepository()
            let ref1 = repo.withGitReference(named: "refs/heads/master") { Reference($0) }
            let ref2 = repo.withGitReference(named: "refs/heads/master") { Reference($0) }
            #expect(ref1 == ref2)
        }
        
        @Test("should be false with unequal references") func notEqual() throws {
            let repo = try fixtures.simpleRepository()
            let ref1 = repo.withGitReference(named: "refs/heads/master") { Reference($0) }
            let ref2 = repo.withGitReference(named: "refs/heads/another-branch") { Reference($0) }
            #expect(ref1 != ref2)
        }
    }
    
    @Suite("Reference.hashValue") class HashValue: FixturesSpec {
        @Test("should be equal with equal references") func equal() throws {
            let repo = try fixtures.simpleRepository()
            let ref1 = repo.withGitReference(named: "refs/heads/master") { Reference($0) }
            let ref2 = repo.withGitReference(named: "refs/heads/master") { Reference($0) }
            #expect(ref1.hashValue == ref2.hashValue)
        }
    }
}

@Suite("Branch") class BranchSpec {
    @Suite("Branch(pointer)") class Initializer: FixturesSpec {
        @Test("should initialize its properties") func properties() throws {
            let repo = try fixtures.mantleRepository()
            let branch = repo.withGitReference(named: "refs/heads/master") { Branch($0)! }
            #expect(branch.longName == "refs/heads/master")
            #expect(branch.name == "master")
            #expect(branch.shortName == branch.name)
            let expectedOID = try #require(OID(string: "f797bd4837b61d37847a4833024aab268599a681"))
            #expect(branch.commit.oid == expectedOID)
            #expect(branch.oid == branch.commit.oid)
            #expect(branch.isLocal == true)
            #expect(branch.isRemote == false)
        }
        
        @Test("should work with symoblic refs") func symbolicRef() throws {
            let repo = try fixtures.mantleRepository()
            let branch = repo.withGitReference(named: "refs/remotes/origin/HEAD") { Branch($0)! }
            #expect(branch.longName == "refs/remotes/origin/HEAD")
            #expect(branch.name == "origin/HEAD")
            #expect(branch.shortName == branch.name)
            let expectedOID = try #require(OID(string: "f797bd4837b61d37847a4833024aab268599a681"))
            #expect(branch.commit.oid == expectedOID)
            #expect(branch.oid == branch.commit.oid)
            #expect(branch.isLocal == false)
            #expect(branch.isRemote == true)
        }
    }
    
    @Suite("==(Branch, Branch)") class Equality: FixturesSpec {
        @Test("should be true with equal branches") func equal() throws {
            let repo = try fixtures.simpleRepository()
            let branch1 = repo.withGitReference(named: "refs/heads/master") { Branch($0)! }
            let branch2 = repo.withGitReference(named: "refs/heads/master") { Branch($0)! }
            #expect(branch1 == branch2)
        }
        
        @Test("should be false with unequal branches") func notEqual() throws {
            let repo = try fixtures.simpleRepository()
            let branch1 = repo.withGitReference(named: "refs/heads/master") { Branch($0)! }
            let branch2 = repo.withGitReference(named: "refs/heads/another-branch") { Branch($0)! }
            #expect(branch1 != branch2)
        }
    }
    
    @Suite("Branch.hashValue") class HashValue: FixturesSpec {
        @Test("should be equal with equal references") func equal() throws {
            let repo = try fixtures.simpleRepository()
            let branch1 = repo.withGitReference(named: "refs/heads/master") { Branch($0)! }
            let branch2 = repo.withGitReference(named: "refs/heads/master") { Branch($0)! }
            #expect(branch1.hashValue == branch2.hashValue)
        }
    }
}

@Suite("TagReference") class TagReferenceSpec {
    
    @Suite("TagReference(pointer)") class InitializeWithPointer: FixturesSpec {
        @Test("should work with an annotated tag") func annotatedTag() throws {
            let repo = try fixtures.simpleRepository()
            let tag = repo.withGitReference(named: "refs/tags/tag-2") { TagReference($0)! }
            #expect(tag.longName == "refs/tags/tag-2")
            #expect(tag.name == "tag-2")
            #expect(tag.shortName == tag.name)
            let expectedOID = try #require(OID(string: "24e1e40ee77525d9e279f079f9906ad6d98c8940"))
            #expect(tag.oid == expectedOID)
        }
        
        @Test("should work with a lightweight tag") func lightweightTag() throws {
            let repo = try fixtures.mantleRepository()
            let tag = repo.withGitReference(named: "refs/tags/1.5.4") { TagReference($0)! }
            #expect(tag.longName == "refs/tags/1.5.4")
            #expect(tag.name == "1.5.4")
            #expect(tag.shortName == tag.name)
            let expectedOID = try #require(OID(string: "d9dc95002cfbf3929d2b70d2c8a77e6bf5b1b88a"))
            #expect(tag.oid == expectedOID)
        }
        
        @Test("should return nil if not a tag") func notATag() throws {
            let repo = try fixtures.simpleRepository()
            let tag = repo.withGitReference(named: "refs/heads/master") { TagReference($0) }
            #expect(tag == nil)
        }
    }
    
    @Suite("==(TagReference, TagReference)") class Equality: FixturesSpec {
        @Test("should be true with equal tag references") func equal() throws {
            let repo = try fixtures.simpleRepository()
            let tag1 = repo.withGitReference(named: "refs/tags/tag-2") { TagReference($0)! }
            let tag2 = repo.withGitReference(named: "refs/tags/tag-2") { TagReference($0)! }
            #expect(tag1 == tag2)
        }
        
        @Test("should be false with unequal tag references") func notEqual() throws {
            let repo = try fixtures.simpleRepository()
            let tag1 = repo.withGitReference(named: "refs/tags/tag-1") { TagReference($0)! }
            let tag2 = repo.withGitReference(named: "refs/tags/tag-2") { TagReference($0)! }
            #expect(tag1 != tag2)
        }
    }
    
    @Suite("TagReference.hashValue") class HashValue: FixturesSpec {
        @Test("should be equal with equal references") func equal() throws {
            let repo = try fixtures.simpleRepository()
            let tag1 = repo.withGitReference(named: "refs/tags/tag-2") { TagReference($0)! }
            let tag2 = repo.withGitReference(named: "refs/tags/tag-2") { TagReference($0)! }
            #expect(tag1.hashValue == tag2.hashValue)
        }
    }
}
