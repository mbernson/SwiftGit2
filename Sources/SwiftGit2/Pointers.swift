//
//  Pointers.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 12/23/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import libgit2

/// A pointer to a git object.
public protocol PointerType: Hashable {
    /// The OID of the referenced object.
    var oid: OID { get }

    /// The type of the referenced object.
    var type: GitObjectType { get }
}

public extension PointerType {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.oid == rhs.oid
            && lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(oid)
    }
}

/// A pointer to a git object.
public enum Pointer: PointerType {
    case commit(OID)
    case tree(OID)
    case blob(OID)
    case tag(OID)

    public var oid: OID {
        switch self {
        case let .commit(oid):
            return oid
        case let .tree(oid):
            return oid
        case let .blob(oid):
            return oid
        case let .tag(oid):
            return oid
        }
    }

    public var type: GitObjectType {
        switch self {
        case .commit:
            return .commit
        case .tree:
            return .tree
        case .blob:
            return .blob
        case .tag:
            return .tag
        }
    }

    /// Create an instance with an OID and a libgit2 `git_object_t`.
    init?(oid: OID, type: git_object_t) {
        switch type {
        case GIT_OBJECT_COMMIT:
            self = .commit(oid)
        case GIT_OBJECT_TREE:
            self = .tree(oid)
        case GIT_OBJECT_BLOB:
            self = .blob(oid)
        case GIT_OBJECT_TAG:
            self = .tag(oid)
        default:
            return nil
        }
    }
}

extension Pointer: CustomStringConvertible {
    public var description: String {
        switch self {
        case .commit:
            return "commit(\(oid))"
        case .tree:
            return "tree(\(oid))"
        case .blob:
            return "blob(\(oid))"
        case .tag:
            return "tag(\(oid))"
        }
    }
}

public struct PointerTo<T: ObjectType>: PointerType {
    public let oid: OID

    public var type: GitObjectType {
        return T.type
    }

    init(_ oid: OID) {
        self.oid = oid
    }
}
