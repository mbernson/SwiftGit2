//
//  OIDSpec.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/17/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import SwiftGit2
import Testing

@Suite("OID") class OIDSpec {
    @Suite("OID(string:)") struct InitializeWithString {
        @Test("should be nil if string is too short") func tooShort() {
            #expect(OID(string: "123456789012345678901234567890123456789") == nil)
        }

        @Test("should be nil if string is too long") func tooLong() {
            #expect(OID(string: "12345678901234567890123456789012345678901") == nil)
        }

        @Test("should not be nil if string is just right") func justRight() {
            #expect(OID(string: "1234567890123456789012345678ABCDEFabcdef") != nil)
        }

        @Test("should be nil with non-hex characters") func invalidCharacters() {
            #expect(OID(string: "123456789012345678901234567890123456789j") == nil)
        }
    }

    @Suite("OID(oid)") struct InitializeWithOID {
        @Test("should equal an OID with the same git_oid") func equal() throws {
            let oid = try #require(OID(string: "1234567890123456789012345678901234567890"))
            #expect(OID(oid.oid) == oid)
        }
    }

    @Suite("OID.description") struct Description {
        @Test("should return the SHA") func sha() throws {
            let SHA = "1234567890123456789012345678901234567890"
            let oid = try #require(OID(string: SHA))
            #expect(oid.description == SHA)
        }
    }

    @Suite("==(OID, OID)") struct Equality {
        @Test("should be equal when identical") func equal() throws {
            let SHA = "1234567890123456789012345678901234567890"
            let oid1 = try #require(OID(string: SHA))
            let oid2 = try #require(OID(string: SHA))
            #expect(oid1 == oid2)
        }

        @Test("should be not equal when different") func notEqual() throws {
            let oid1 = try #require(OID(string: "1234567890123456789012345678901234567890"))
            let oid2 = try #require(OID(string: "0000000000000000000000000000000000000000"))
            #expect(oid1 != oid2)
        }
    }

    @Suite("OID.hashValue") struct HashValue {
        @Test("should be equal when OIDs are equal") func equal() throws {
            let SHA = "1234567890123456789012345678901234567890"
            let oid1 = try #require(OID(string: SHA))
            let oid2 = try #require(OID(string: SHA))
            #expect(oid1.hashValue == oid2.hashValue)
        }
    }
}
