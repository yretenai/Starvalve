// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

/// A steam library folder and it's associated metadata.
public struct SteamLibraryFolder: VDFContent {
	public var path: String = ""
	public var label: String? = nil
	public var contentID: UInt = 0
	public var totalSize: UInt = 0
	public var updateCleanBytesTally: UInt = 0
	public var timeLastUpdateVerified: Date = Date(timeIntervalSince1970: TimeInterval(0))
	public var apps: [UInt: UInt] = [:]

	public init?(vdf: ValveKeyValue) {
		guard let path = vdf["path"]?.string else {
			return nil
		}

		self.path = path
		label = vdf["label"]?.string
		contentID = vdf["contentID"]?.unsigned ?? 0
		totalSize = vdf["totalSize"]?.unsigned ?? 0
		updateCleanBytesTally = vdf["update_clean_bytes_tally"]?.unsigned ?? 0
		timeLastUpdateVerified = Date(timeIntervalSince1970: TimeInterval(vdf["time_last_update_verified"]?.unsigned ?? 0))
		apps = vdf["apps"]?.to(key: UInt.self, value: UInt.self) ?? [:]
	}

	public func vdf() -> ValveKeyValue {
		let vdf = ValveKeyValue(ValveKeyValueNode("libraryfolder"))
		vdf[ValveKeyValueNode("path")] = ValveKeyValueNode(path)
		vdf[ValveKeyValueNode("label")] = ValveKeyValueNode(label ?? "")
		vdf[ValveKeyValueNode("contentid")] = ValveKeyValueNode(unsigned: contentID)
		vdf[ValveKeyValueNode("totalsize")] = ValveKeyValueNode(unsigned: totalSize)
		vdf[ValveKeyValueNode("update_clean_bytes_tally")] = ValveKeyValueNode(unsigned: updateCleanBytesTally)
		vdf[ValveKeyValueNode("time_last_update_verified")] = ValveKeyValueNode(unsigned: UInt(timeLastUpdateVerified.timeIntervalSince1970))
		vdf.append(ValveKeyValue(key: ValveKeyValueNode("apps"), map: apps))
		return vdf
	}
}

/// All steam library folders.
public struct SteamLibraryFolders: VDFContent {
	public var entries: [SteamLibraryFolder] = []

	public init?(vdf: ValveKeyValue) {
		entries = vdf.to(sequence: SteamLibraryFolder.self)
	}

	public func vdf() -> ValveKeyValue {
		ValveKeyValue(key: ValveKeyValueNode("libraryfolders"), sequence: entries)
	}
}
