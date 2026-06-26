//
//  ObjectSpec.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 12/4/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation
import SwiftGit2
import Testing
import Clibgit2

private extension Repository {
	func withGitObject<T>(_ oid: OID, transform: (OpaquePointer) -> T) -> T {
		let repository = self.pointer
		var oid = oid.oid

		var pointer: OpaquePointer? = nil
		git_object_lookup(&pointer, repository, &oid, GIT_OBJECT_ANY)
		let result = transform(pointer!)
		git_object_free(pointer)

		return result
	}
}

@Suite("Signature") class SignatureSpec {
    @Suite("Signature(signature)") class Initializer: FixturesSpec {
        @Test("should initialize its properties") func properties() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))

            let raw_signature = repo.withGitObject(oid) { git_commit_author($0).pointee }
            let signature = Signature(raw_signature)

            #expect(signature.name == "Matt Diephouse")
            #expect(signature.email == "matt@diephouse.com")
            #expect(signature.time == Date(timeIntervalSince1970: 1416186947))
            #expect(signature.timeZone.abbreviation() == "GMT-5")
        }
    }

    @Suite("==(Signature, Signature)") class Equality: FixturesSpec {
        @Test("should be true with equal objects") func equalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))

            let author1 = repo.withGitObject(oid) { commit in
                Signature(git_commit_author(commit).pointee)
            }
            let author2 = author1

            #expect(author1 == author2)
        }

        @Test("should be false with unequal objects") func unequalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid1 = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))
            let oid2 = try #require(OID(string: "24e1e40ee77525d9e279f079f9906ad6d98c8940"))

            let author1 = repo.withGitObject(oid1) { commit in
                Signature(git_commit_author(commit).pointee)
            }
            let author2 = repo.withGitObject(oid2) { commit in
                Signature(git_commit_author(commit).pointee)
            }

            #expect(author1 != author2)
        }
    }

    @Suite("Signature.hashValue") class HashValue: FixturesSpec {
        @Test("should be equal with equal objects") func equalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))

            let author1 = repo.withGitObject(oid) { commit in
                Signature(git_commit_author(commit).pointee)
            }
            let author2 = author1

            #expect(author1.hashValue == author2.hashValue)
        }
    }
}

@Suite("Commit") class CommitSpec {
    @Suite("Commit(pointer)") class Initializer: FixturesSpec {
        @Test("should initialize its properties") func properties() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "24e1e40ee77525d9e279f079f9906ad6d98c8940"))

            let commit = repo.withGitObject(oid) { Commit($0) }
            let author = repo.withGitObject(oid) { commit in
                Signature(git_commit_author(commit).pointee)
            }
            let committer = repo.withGitObject(oid) { commit in
                Signature(git_commit_committer(commit).pointee)
            }
            let tree = PointerTo<Tree>(try #require(OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31")))
            let parents: [PointerTo<Commit>] = [
                PointerTo(try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))),
            ]
            #expect(commit.oid == oid)
            #expect(commit.tree == tree)
            #expect(commit.parents == parents)
            #expect(commit.summary == "List branches in README")
            #expect(commit.body == nil)
            #expect(commit.message == "List branches in README\n")
            #expect(commit.timestamp == Date(timeIntervalSince1970: 1417876367))
            #expect(commit.author == author)
            #expect(commit.committer == committer)
        }

        @Test("should set the body for a commit with a multi-line message") func body() throws {
            let repo = try fixtures.mantleRepository()
            let oid = try #require(OID(string: "d9dc95002cfbf3929d2b70d2c8a77e6bf5b1b88a"))

            let commit = repo.withGitObject(oid) { Commit($0) }
            #expect(commit.summary == "Merge pull request #437 from Mantle/pacify-xcode")
            #expect(commit.body == "Pacify Xcode")
        }

        @Test("should handle 0 parents") func zeroParents() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))

            let commit = repo.withGitObject(oid) { Commit($0) }
            #expect(commit.parents == [])
        }

        @Test("should handle multiple parents") func multipleParents() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "c4ed03a6b7d7ce837d31d83757febbe84dd465fd"))

            let commit = repo.withGitObject(oid) { Commit($0) }
            let parents: [PointerTo<Commit>] = [
                PointerTo(try #require(OID(string: "315b3f344221db91ddc54b269f3c9af422da0f2e"))),
                PointerTo(try #require(OID(string: "57f6197561d1f99b03c160f4026a07f06b43cf20"))),
            ]
            #expect(commit.parents == parents)
        }
    }

    @Suite("==(Commit, Commit)") class Equality: FixturesSpec {
        @Test("should be true with equal objects") func equalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))

            let commit1 = repo.withGitObject(oid) { Commit($0) }
            let commit2 = commit1
            #expect(commit1 == commit2)
        }

        @Test("should be false with unequal objects") func unequalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid1 = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))
            let oid2 = try #require(OID(string: "c4ed03a6b7d7ce837d31d83757febbe84dd465fd"))

            let commit1 = repo.withGitObject(oid1) { Commit($0) }
            let commit2 = repo.withGitObject(oid2) { Commit($0) }
            #expect(commit1 != commit2)
        }
    }

    @Suite("Commit.hashValue") class HashValue: FixturesSpec {
        @Test("should be equal with equal objects") func equalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))

            let commit1 = repo.withGitObject(oid) { Commit($0) }
            let commit2 = commit1
            #expect(commit1.hashValue == commit2.hashValue)
        }
    }
}

@Suite("Tree.Entry") class TreeEntrySpec {
    @Suite("Tree.Entry(attributes:object:name:)") class InitializerWithProperties {
        @Test("should set its properties") func shouldSetProperties() throws {
            let attributes = Int32(GIT_FILEMODE_BLOB.rawValue)
            let object = Pointer.blob(try #require(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")))
            let name = "README.md"

            let entry = Tree.Entry(attributes: attributes, object: object, name: name)
            #expect(entry.attributes == attributes)
            #expect(entry.object == object)
            #expect(entry.name == name)
        }
    }

    @Suite("Tree.Entry(pointer)") class InitializerWithPointer: FixturesSpec {
        @Test("should set its properties") func shouldSetProperties() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31"))

            let entry = repo.withGitObject(oid) { Tree.Entry(git_tree_entry_byindex($0, 0)) }
            #expect(entry.attributes == Int32(GIT_FILEMODE_BLOB.rawValue))
            let expectedOID = try #require(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba"))
            #expect(entry.object == Pointer.blob(expectedOID))
            #expect(entry.name == "README.md")
        }
    }

    @Suite("==(Tree.Entry, Tree.Entry)") class Equality: FixturesSpec {
        @Test("should be true with equal objects") func equalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31"))

            let entry1 = repo.withGitObject(oid) { Tree.Entry(git_tree_entry_byindex($0, 0)) }
            let entry2 = entry1
            #expect(entry1 == entry2)
        }

        @Test("should be false with unequal objects") func unequalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid1 = try #require(OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31"))
            let oid2 = try #require(OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc"))

            let entry1 = repo.withGitObject(oid1) { Tree.Entry(git_tree_entry_byindex($0, 0)) }
            let entry2 = repo.withGitObject(oid2) { Tree.Entry(git_tree_entry_byindex($0, 0)) }
            #expect(entry1 != entry2)
        }
    }

    @Suite("Tree.Entry.hashValue") class HashValue: FixturesSpec {
        @Test("should be equal with equal objects") func equalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31"))

            let entry1 = repo.withGitObject(oid) { Tree.Entry(git_tree_entry_byindex($0, 0)) }
            let entry2 = entry1
            #expect(entry1.hashValue == entry2.hashValue)
        }
    }
}

@Suite("Tree") class TreeSpec {
    @Suite("Tree(pointer)") class InitializerWithPointer: FixturesSpec {
        @Test("should initialize its properties") func initialize() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31"))

            let tree = repo.withGitObject(oid) { Tree($0) }
            let entries = [
                "README.md": Tree.Entry(attributes: Int32(GIT_FILEMODE_BLOB.rawValue),
                                        object: .blob(try #require(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba"))),
                                        name: "README.md"),
            ]
            #expect(tree.entries == entries)
        }
    }

    @Suite("==(Tree, Tree)") class Equality: FixturesSpec {
        @Test("should be true with equal objects") func equalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31"))

            let tree1 = repo.withGitObject(oid) { Tree($0) }
            let tree2 = tree1
            #expect(tree1 == tree2)
        }

        @Test("should be false with unequal objects") func unequalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid1 = try #require(OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31"))
            let oid2 = try #require(OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc"))

            let tree1 = repo.withGitObject(oid1) { Tree($0) }
            let tree2 = repo.withGitObject(oid2) { Tree($0) }
            #expect(tree1 != tree2)
        }
    }

    @Suite("Tree.hashValue") class HashValue: FixturesSpec {
        @Test("should be equal with equal objects") func equalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31"))

            let tree1 = repo.withGitObject(oid) { Tree($0) }
            let tree2 = tree1
            #expect(tree1.hashValue == tree2.hashValue)
        }
    }
}

@Suite("Blob") class BlobSpec {
    @Suite("Blob(pointer)") class Initializer: FixturesSpec {
        @Test("should initialize its properties") func initializesProperties() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba"))

            let blob = repo.withGitObject(oid) { Blob($0) }
            let contents = "# Simple Repository\nA simple repository used for testing SwiftGit2.\n\n## Branches\n\n- master\n\n"
            let data = contents.data(using: String.Encoding.utf8)!
            #expect(blob.oid == oid)
            #expect(blob.data == data)
        }
    }

    @Suite("==(Blob, Blob)") class Equality: FixturesSpec {
        @Test("should be true with equal objects") func equalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba"))

            let blob1 = repo.withGitObject(oid) { Blob($0) }
            let blob2 = blob1
            #expect(blob1 == blob2)
        }

        @Test("should be false with unequal objects") func unequalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid1 = try #require(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba"))
            let oid2 = try #require(OID(string: "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391"))

            let blob1 = repo.withGitObject(oid1) { Blob($0) }
            let blob2 = repo.withGitObject(oid2) { Blob($0) }
            #expect(blob1 != blob2)
        }
    }

    @Suite("Blob.hashValue") class HashValue: FixturesSpec {
        @Test("should be equal with equal objects") func equalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba"))

            let blob1 = repo.withGitObject(oid) { Blob($0) }
            let blob2 = blob1
            #expect(blob1.hashValue == blob2.hashValue)
        }
    }
}

@Suite("Tag") class TagSpec {
    @Suite("Tag(pointer)") class Initializer: FixturesSpec {
        @Test("should set its properties") func setsProperties() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "57943b8ee00348180ceeedc960451562750f6d33"))

            let tag = repo.withGitObject(oid) { Tag($0) }
            let tagger = repo.withGitObject(oid) { Signature(git_tag_tagger($0).pointee) }

            #expect(tag.oid == oid)
            let expectedOID = try #require(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a"))
            #expect(tag.target == Pointer.commit(expectedOID))
            #expect(tag.name == "tag-1")
            #expect(tag.tagger == tagger)
            #expect(tag.message == "tag-1\n")
        }
    }

    @Suite("==(Tag, Tag)") class Equality: FixturesSpec {
        @Test("should be true with equal objects") func equalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "57943b8ee00348180ceeedc960451562750f6d33"))

            let tag1 = repo.withGitObject(oid) { Tag($0) }
            let tag2 = tag1
            #expect(tag1 == tag2)
        }

        @Test("should be false with unequal objects") func unequalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid1 = try #require(OID(string: "57943b8ee00348180ceeedc960451562750f6d33"))
            let oid2 = try #require(OID(string: "13bda91157f255ab224ff88d0a11a82041c9d0c1"))

            let tag1 = repo.withGitObject(oid1) { Tag($0) }
            let tag2 = repo.withGitObject(oid2) { Tag($0) }
            #expect(tag1 != tag2)
        }
    }

    @Suite("Tag.hashValue") class HashValue: FixturesSpec {
        @Test("should be equal with equal objects") func equalObjects() throws {
            let repo = try fixtures.simpleRepository()
            let oid = try #require(OID(string: "57943b8ee00348180ceeedc960451562750f6d33"))

            let tag1 = repo.withGitObject(oid) { Tag($0) }
            let tag2 = tag1
            #expect(tag1.hashValue == tag2.hashValue)
        }
    }
}
