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

class FixturesSpec {
    let fixtures: Fixtures

    init() throws {
        _ = SwiftGit2Init()
        self.fixtures = try Fixtures()
    }

    deinit {
        _ = SwiftGit2Shutdown()
    }
}
