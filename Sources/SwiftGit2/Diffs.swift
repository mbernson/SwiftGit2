//
//  Diffs.swift
//  SwiftGit2
//
//  Created by Jake Van Alstyne on 8/20/17.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//

import Clibgit2

public struct StatusEntry {
	public var status: Diff.Status
	public var headToIndex: Diff.Delta?
	public var indexToWorkDir: Diff.Delta?

	public init(from statusEntry: git_status_entry) {
		self.status = Diff.Status(rawValue: statusEntry.status.rawValue)

		if let htoi = statusEntry.head_to_index {
			self.headToIndex = Diff.Delta(htoi.pointee)
		}

		if let itow = statusEntry.index_to_workdir {
			self.indexToWorkDir = Diff.Delta(itow.pointee)
		}
	}
}

public struct Diff: Hashable {

	/// The set of deltas.
	public var deltas = [Delta]()

	public struct Delta: Hashable {
		public var status: Status
		public var flags: Flags
		public var oldFile: File?
		public var newFile: File?

		public init(_ delta: git_diff_delta) {
			self.status = Status(rawValue: UInt32(git_diff_status_char(delta.status)))
			self.flags = Flags(rawValue: delta.flags)
			self.oldFile = File(delta.old_file)
			self.newFile = File(delta.new_file)
		}
	}

	public struct File: Hashable {
		public var oid: OID
		public var path: String
		public var size: UInt64
		public var flags: Flags

		public init(_ diffFile: git_diff_file) {
			self.oid = OID(diffFile.id)
			let path = diffFile.path
			self.path = path.map(String.init(cString:))!
			self.size = diffFile.size
			self.flags = Flags(rawValue: diffFile.flags)
		}
	}

	public struct Status: OptionSet, Hashable {
		// This appears to be necessary due to bug in Swift
		// https://bugs.swift.org/browse/SR-3003
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		public let rawValue: UInt32

		public static let current                = Status(rawValue: GIT_STATUS_CURRENT.rawValue)
		public static let indexNew               = Status(rawValue: GIT_STATUS_INDEX_NEW.rawValue)
		public static let indexModified          = Status(rawValue: GIT_STATUS_INDEX_MODIFIED.rawValue)
		public static let indexDeleted           = Status(rawValue: GIT_STATUS_INDEX_DELETED.rawValue)
		public static let indexRenamed           = Status(rawValue: GIT_STATUS_INDEX_RENAMED.rawValue)
		public static let indexTypeChange        = Status(rawValue: GIT_STATUS_INDEX_TYPECHANGE.rawValue)
		public static let workTreeNew            = Status(rawValue: GIT_STATUS_WT_NEW.rawValue)
		public static let workTreeModified       = Status(rawValue: GIT_STATUS_WT_MODIFIED.rawValue)
		public static let workTreeDeleted        = Status(rawValue: GIT_STATUS_WT_DELETED.rawValue)
		public static let workTreeTypeChange     = Status(rawValue: GIT_STATUS_WT_TYPECHANGE.rawValue)
		public static let workTreeRenamed        = Status(rawValue: GIT_STATUS_WT_RENAMED.rawValue)
		public static let workTreeUnreadable     = Status(rawValue: GIT_STATUS_WT_UNREADABLE.rawValue)
		public static let ignored                = Status(rawValue: GIT_STATUS_IGNORED.rawValue)
		public static let conflicted             = Status(rawValue: GIT_STATUS_CONFLICTED.rawValue)
	}

	public struct Flags: OptionSet, Hashable {
		// This appears to be necessary due to bug in Swift
		// https://bugs.swift.org/browse/SR-3003
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		public let rawValue: UInt32

		public static let binary     = Flags([])
		public static let notBinary  = Flags(rawValue: 1 << 0)
		public static let validId    = Flags(rawValue: 1 << 1)
		public static let exists     = Flags(rawValue: 1 << 2)
	}

	/// Create an instance with a libgit2 `git_diff`.
	public init(_ pointer: OpaquePointer) {
		for i in 0..<git_diff_num_deltas(pointer) {
			if let delta = git_diff_get_delta(pointer, i) {
				deltas.append(Diff.Delta(delta.pointee))
			}
		}
	}
}

public extension Diff {

	/// A single delta together with its hunk-level diff content.
	struct Patch: Hashable {
		public var delta: Delta
		public var hunks: [Hunk]
		/// Number of added lines across all hunks.
		public var additions: Int
		/// Number of deleted lines across all hunks.
		public var deletions: Int
		/// Number of context (unchanged) lines across all hunks.
		public var context: Int
		/// The full unified-diff text for this delta. Empty for binary or
		/// unchanged files, which have no textual patch.
		public var text: String

		public init(delta: Delta, hunks: [Hunk],
		            additions: Int = 0, deletions: Int = 0, context: Int = 0,
		            text: String = "") {
			self.delta = delta
			self.hunks = hunks
			self.additions = additions
			self.deletions = deletions
			self.context = context
			self.text = text
		}
	}

	/// A contiguous range of changed lines within a delta, plus its context.
	struct Hunk: Hashable {
		public var oldStart: Int
		public var oldLines: Int
		public var newStart: Int
		public var newLines: Int
		/// The hunk header, e.g. `@@ -1,4 +1,6 @@ ...`.
		public var header: String
		public var lines: [Line]

		public init(_ hunk: git_diff_hunk, lines: [Line]) {
			self.oldStart = Int(hunk.old_start)
			self.oldLines = Int(hunk.old_lines)
			self.newStart = Int(hunk.new_start)
			self.newLines = Int(hunk.new_lines)
			self.lines = lines

			// `header` is a fixed C char array, NUL-terminated within `header_len` bytes.
			var hunk = hunk
			self.header = withUnsafeBytes(of: &hunk.header) { raw in
				let bytes = raw.bindMemory(to: UInt8.self)
				let count = min(Int(hunk.header_len), bytes.count)
				return String(decoding: bytes[0..<count], as: UTF8.self)
			}
		}
	}

	/// A single line (or data span) within a hunk.
	struct Line: Hashable {

		/// Where a line came from. Mirrors `git_diff_line_t` for the values that
		/// are delivered while walking a diff (the print-only origins are omitted).
		public enum Origin: Character {
			case context     = " "
			case addition    = "+"
			case deletion    = "-"
			case contextEOFNL = "="
			case addEOFNL    = ">"
			case delEOFNL    = "<"
		}

		public var origin: Origin
		/// Line number in the old file, or -1 for an added line.
		public var oldLineno: Int
		/// Line number in the new file, or -1 for a deleted line.
		public var newLineno: Int
		/// The line's text content.
		public var content: String

		public init(_ line: git_diff_line) {
			// Unknown / print-only origins fall back to `.context` so the walk never crashes.
			self.origin = Origin(rawValue: Character(UnicodeScalar(UInt8(bitPattern: line.origin)))) ?? .context
			self.oldLineno = Int(line.old_lineno)
			self.newLineno = Int(line.new_lineno)

			// `content` is not NUL-terminated; it's a span of `content_len` bytes.
			if let contentPtr = line.content, line.content_len > 0 {
				let buffer = UnsafeRawBufferPointer(start: contentPtr, count: line.content_len)
				self.content = String(decoding: buffer, as: UTF8.self)
			} else {
				self.content = ""
			}
		}
	}
}
