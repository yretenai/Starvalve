// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

#if os(macOS)
	private typealias FileBool = ObjCBool
#else
	private typealias FileBool = Bool
#endif

extension FileManager {
	func dirExists(atPath path: String) -> Bool {
		var isDirectory: FileBool = false
		guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
			return false
		}

		#if os(macOS)
			return isDirectory.boolValue
		#else
			return isDirectory
		#endif
	}
}
