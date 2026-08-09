//
//  FixturesSpec.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/16/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import SwiftGit2
import Testing
import Clibgit2

/// Base class for every suite that touches libgit2. Calling into libgit2 before `SwiftGit2Init()` is
/// undefined behaviour: its error reporting then writes through an uninitialized thread-local key.
class Libgit2Spec {
    init() throws {
        _ = try SwiftGit2Init().get()
    }

    deinit {
        _ = SwiftGit2Shutdown()
    }
}

class FixturesSpec: Libgit2Spec {
    let fixtures: Fixtures

    override init() throws {
        self.fixtures = try Fixtures()
        try super.init()
    }
}
