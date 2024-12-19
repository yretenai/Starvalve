// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

/// Stored data of a particular steam package.
public struct SteamPackageData {
	public let packageId: UInt32
	public let hash: Data
	public let changeId: UInt32
	public let contentId: UInt64
	public let vdf: ValveKeyValue

	internal init?(version: Int, data: DataCursor) throws {
		packageId = try data.read(as: UInt32.self)
		if packageId == 0xFFFF_FFFF {
			return nil
		}

		hash = try data.readBytes(count: 20)
		changeId = try data.read(as: UInt32.self)
		if version >= 28 {
			contentId = try data.read(as: UInt64.self)
		} else {
			contentId = 0
		}
		vdf = ValveKeyValue(ValveKeyValueNode(""))  // todo: read binary object
	}
}

/// packageinfo.vdf file format.
public struct SteamPackageInfo {
	public let version: Int
	public let universe: SteamUniverse
	public let packages: [SteamPackageData]

	public init(version: Int, data: Data) throws {
		let cursor = DataCursor(data)
		let version = try data.read(as: UInt32.self)
		guard (version & 0xFFFFFF) == 0x75644 else {
			throw SteamAppInfoError.unsupported
		}

		self.version = Int(version >> 24)

		guard self.version >= 27 && self.version <= 28 else {
			throw SteamAppInfoError.unsupported
		}

		guard let universe = SteamUniverse(rawValue: Int(try cursor.read(as: UInt32.self))) else {
			throw SteamAppInfoError.unsupported
		}

		self.universe = universe

		var packages: [SteamPackageData] = []
		while let package = try? SteamPackageData(version: self.version, data: cursor) {
			packages.append(package)
		}
		self.packages = packages
	}
}
