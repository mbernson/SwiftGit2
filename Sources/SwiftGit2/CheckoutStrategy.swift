//
//  CheckoutStrategy.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 4/1/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

import Clibgit2

/// The flags defining how a checkout should be performed.
/// More detail is available in the libgit2 documentation for `git_checkout_strategy_t`.
public struct CheckoutStrategy: OptionSet {
	private let value: UInt

	// MARK: - Initialization

	/// Create an instance initialized with `nil`.
	public init(nilLiteral: ()) {
		self.value = 0
	}

	public init(rawValue value: UInt) {
		self.value = value
	}

	public init(_ strategy: git_checkout_strategy_t) {
		self.value = UInt(strategy.rawValue)
	}

	public static var allZeros: CheckoutStrategy {
		return self.init(rawValue: 0)
	}

	// MARK: - Properties

	public var rawValue: UInt {
		return value
	}

	public var gitCheckoutStrategy: git_checkout_strategy_t {
		return git_checkout_strategy_t(UInt32(self.value))
	}

	// MARK: - Values

	/// Do not do a checkout and do not fire callbacks; this is primarily
	/// useful only for internal functions that will perform the checkout
	/// themselves but need to pass checkout options into another function.
	public static let none = CheckoutStrategy(GIT_CHECKOUT_NONE)

	/// Allow safe updates that cannot overwrite uncommitted data.
	public static let safe = CheckoutStrategy(GIT_CHECKOUT_SAFE)

	/// Allow all updates to force working directory to look like index
	public static let force = CheckoutStrategy(GIT_CHECKOUT_FORCE)

	/// Allow checkout to recreate missing files.
	public static let recreateMissing = CheckoutStrategy(GIT_CHECKOUT_RECREATE_MISSING)

	/// Allow checkout to make safe updates even if conflicts are found.
	public static let allowConflicts = CheckoutStrategy(GIT_CHECKOUT_ALLOW_CONFLICTS)

	/// Remove untracked files not in index (that are not ignored).
	public static let removeUntracked = CheckoutStrategy(GIT_CHECKOUT_REMOVE_UNTRACKED)

	/// Remove ignored files not in index.
	public static let removeIgnored = CheckoutStrategy(GIT_CHECKOUT_REMOVE_IGNORED)

	/// Only update existing files, don't create new ones.
	public static let updateOnly = CheckoutStrategy(GIT_CHECKOUT_UPDATE_ONLY)

	/// Normally checkout updates index entries as it goes; this stops that.
	/// Implies `dontWriteIndex`.
	public static let dontUpdateIndex = CheckoutStrategy(GIT_CHECKOUT_DONT_UPDATE_INDEX)

	/// Don't refresh index/config/etc before doing checkout
	public static let noRefresh = CheckoutStrategy(GIT_CHECKOUT_NO_REFRESH)

	/// Allow checkout to skip unmerged files
	public static let skipUnmerged = CheckoutStrategy(GIT_CHECKOUT_SKIP_UNMERGED)

	/// For unmerged files, checkout stage 2 from index
	public static let useOurs = CheckoutStrategy(GIT_CHECKOUT_USE_OURS)

	/// For unmerged files, checkout stage 3 from index
	public static let useTheirs = CheckoutStrategy(GIT_CHECKOUT_USE_THEIRS)

	/// Treat pathspec as simple list of exact match file paths
	public static let disablePathspecMatch = CheckoutStrategy(GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH)

	/// Ignore directories in use, they will be left empty
	public static let skipLockedDirectories = CheckoutStrategy(GIT_CHECKOUT_SKIP_LOCKED_DIRECTORIES)

	/// Don't overwrite ignored files that exist in the checkout target
	public static let dontOverwriteIgnored = CheckoutStrategy(GIT_CHECKOUT_DONT_OVERWRITE_IGNORED)

	/// Write normal merge files for conflicts
	public static let conflictStyleMerge = CheckoutStrategy(GIT_CHECKOUT_CONFLICT_STYLE_MERGE)

	/// Include common ancestor data in diff3 format files for conflicts
	public static let conflictStyleDiff3 = CheckoutStrategy(GIT_CHECKOUT_CONFLICT_STYLE_DIFF3)

	/// Don't overwrite existing files or folders
	public static let dontRemoveExisting = CheckoutStrategy(GIT_CHECKOUT_DONT_REMOVE_EXISTING)

	/// Normally checkout writes the index upon completion; this prevents that.
	public static let dontWriteIndex = CheckoutStrategy(GIT_CHECKOUT_DONT_WRITE_INDEX)

	/// Perform a "dry run", reporting what _would_ be done but without actually
	/// making changes in the working directory or the index.
	public static let dryRun = CheckoutStrategy(GIT_CHECKOUT_DRY_RUN)

	/// Include common ancestor data in zdiff3 format for conflicts
	public static let conflictStyleZdiff3 = CheckoutStrategy(GIT_CHECKOUT_CONFLICT_STYLE_ZDIFF3)

	/// Recursively checkout submodules with same options (NOT IMPLEMENTED)
	public static let updateSubmodules = CheckoutStrategy(GIT_CHECKOUT_UPDATE_SUBMODULES)

	/// Recursively checkout submodules if HEAD moved in super repo (NOT IMPLEMENTED)
	public static let updateSubmodulesIfChanged = CheckoutStrategy(GIT_CHECKOUT_UPDATE_SUBMODULES_IF_CHANGED)
}

// MARK: - Legacy names

extension CheckoutStrategy {
	@available(*, deprecated, renamed: "none")
	public static let None = CheckoutStrategy.none

	@available(*, deprecated, renamed: "safe")
	public static let Safe = CheckoutStrategy.safe

	@available(*, deprecated, renamed: "force")
	public static let Force = CheckoutStrategy.force

	@available(*, deprecated, renamed: "recreateMissing")
	public static let RecreateMissing = CheckoutStrategy.recreateMissing

	@available(*, deprecated, renamed: "allowConflicts")
	public static let AllowConflicts = CheckoutStrategy.allowConflicts

	@available(*, deprecated, renamed: "removeUntracked")
	public static let RemoveUntracked = CheckoutStrategy.removeUntracked

	@available(*, deprecated, renamed: "removeIgnored")
	public static let RemoveIgnored = CheckoutStrategy.removeIgnored

	@available(*, deprecated, renamed: "updateOnly")
	public static let UpdateOnly = CheckoutStrategy.updateOnly

	@available(*, deprecated, renamed: "dontUpdateIndex")
	public static let DontUpdateIndex = CheckoutStrategy.dontUpdateIndex

	@available(*, deprecated, renamed: "noRefresh")
	public static let NoRefresh = CheckoutStrategy.noRefresh

	@available(*, deprecated, renamed: "skipUnmerged")
	public static let SkipUnmerged = CheckoutStrategy.skipUnmerged

	@available(*, deprecated, renamed: "useOurs")
	public static let UseOurs = CheckoutStrategy.useOurs

	@available(*, deprecated, renamed: "useTheirs")
	public static let UseTheirs = CheckoutStrategy.useTheirs

	@available(*, deprecated, renamed: "disablePathspecMatch")
	public static let DisablePathspecMatch = CheckoutStrategy.disablePathspecMatch

	@available(*, deprecated, renamed: "skipLockedDirectories")
	public static let SkipLockedDirectories = CheckoutStrategy.skipLockedDirectories

	@available(*, deprecated, renamed: "dontOverwriteIgnored")
	public static let DontOverwriteIgnored = CheckoutStrategy.dontOverwriteIgnored

	@available(*, deprecated, renamed: "conflictStyleMerge")
	public static let ConflictStyleMerge = CheckoutStrategy.conflictStyleMerge

	@available(*, deprecated, renamed: "conflictStyleDiff3")
	public static let ConflictStyleDiff3 = CheckoutStrategy.conflictStyleDiff3

	@available(*, deprecated, renamed: "dontRemoveExisting")
	public static let DontRemoveExisting = CheckoutStrategy.dontRemoveExisting

	@available(*, deprecated, renamed: "dontWriteIndex")
	public static let DontWriteIndex = CheckoutStrategy.dontWriteIndex
}
