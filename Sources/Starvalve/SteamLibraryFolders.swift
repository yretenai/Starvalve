// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

/// A steam library folder and it's associated metadata.
public class SteamLibraryFolder: VDFContent {
	public var path: URL
	public var label: String? = nil
	public var contentID: UInt = 0
	public var totalSize: UInt = 0
	public var appSize: UInt = 0
	public var updateCleanBytesTally: UInt = 0
	public var timeLastUpdateCorrpution: Date = Date(timeIntervalSince1970: 0)
	public var timeLastUpdateVerified: Date = Date(timeIntervalSince1970: 0)
	public var apps: [UInt: UInt] = [:]

	public required init?(vdf: ValveKeyValue) {
		guard let path = vdf["path"]?.string else {
			return nil
		}

		self.path = URL(filePath: path, directoryHint: .isDirectory)
		if let label = vdf["label"]?.string {
			if !label.isEmpty {
				self.label = label
			}
		}
		contentID = vdf["contentID"]?.unsigned ?? 0
		totalSize = vdf["totalSize"]?.unsigned ?? 0
		updateCleanBytesTally = vdf["update_clean_bytes_tally"]?.unsigned ?? 0
		timeLastUpdateCorrpution = vdf["time_last_update_corruption"]?.date ?? Date(timeIntervalSince1970: 0)
		timeLastUpdateVerified = vdf["time_last_update_verified"]?.date ?? Date(timeIntervalSince1970: 0)
		apps = vdf["apps"]?.to(key: UInt.self, value: UInt.self) ?? [:]

		appSize = apps.map { (key, value) in
			value
		}.reduce(0, +)
	}

	public func vdf() -> ValveKeyValue {
		let vdf = ValveKeyValue("libraryfolder")
		vdf["path"] = ValveKeyValueNode(path.path)
		vdf["label"] = ValveKeyValueNode(label ?? "")
		vdf["contentid"] = ValveKeyValueNode(unsigned: contentID)
		vdf["totalsize"] = ValveKeyValueNode(unsigned: totalSize)
		vdf["update_clean_bytes_tally"] = ValveKeyValueNode(unsigned: updateCleanBytesTally)
		if timeLastUpdateCorrpution.timeIntervalSince1970 > 0 {
			vdf["time_last_update_corruption"] = ValveKeyValueNode(epoch: timeLastUpdateCorrpution)
		}
		vdf["time_last_update_verified"] = ValveKeyValueNode(epoch: timeLastUpdateVerified)
		vdf.append(ValveKeyValue(key: "apps", map: apps))
		return vdf
	}

	public func singleVdf() -> ValveKeyValue {
		let vdf = ValveKeyValue("libraryfolder")
		vdf["contentid"] = ValveKeyValueNode(unsigned: contentID)
		vdf["label"] = ValveKeyValueNode(label ?? "")
		return vdf
	}
}

/// All steam library folders.
public class SteamLibraryFolders: VDFContent {
	public var entries: [SteamLibraryFolder] = []

	public required init?(vdf: ValveKeyValue) {
		entries = vdf.to(sequence: SteamLibraryFolder.self)
	}

	public func vdf() -> ValveKeyValue {
		ValveKeyValue(key: "libraryfolders", sequence: entries)
	}
}
