// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

/// The state a given app is in.
public enum SteamAppState: UInt32 {
	case invalid
	case prerelease
	case released
}

/// Stored data of a particular steam app.
public struct SteamAppData {
	public let appId: UInt32
	public let state: SteamAppState
	public let lastUpdated: UInt32
	public let contentId: UInt64
	public let textHash: Data
	public let changeId: UInt32
	public let hash: Data
	public let vdf: ValveKeyValue

	internal init?(version: Int, data: DataCursor, stringTable: [ValveKeyValueNode]?) throws {
		appId = try data.read(as: UInt32.self)
		if appId == 0xFFFF_FFFF || appId == 0 {
			return nil
		}

		let size = Data.Index(try data.read(as: UInt32.self))
		let end = data.index + size

		state = SteamAppState(rawValue: try data.read(as: UInt32.self)) ?? .invalid
		lastUpdated = try data.read(as: UInt32.self)
		contentId = try data.read(as: UInt64.self)
		textHash = try data.readBytes(count: 20)
		changeId = try data.read(as: UInt32.self)
		if version >= 0x28 {
			hash = try data.readBytes(count: 20)
		} else {
			hash = textHash
		}

		guard let vdf = try BinaryVDF.read(data: data, stringTable: stringTable) else {
			throw SteamAppInfoError.invalidVdf
		}
		self.vdf = vdf

		guard data.index == end else {
			throw SteamAppInfoError.invalidVdf
		}
	}
}

/// appinfo.vdf file format.
public struct SteamAppInfo {
	public let version: Int
	public let universe: SteamUniverse
	public let apps: [SteamAppData]

	public init(data: Data) throws {
		let cursor = DataCursor(data)
		let version = try cursor.read(as: UInt32.self)
		guard (version >> 8) == 0x75644 else {
			throw SteamAppInfoError.unsupported
		}

		self.version = Int(version & 0xFF)

		guard self.version >= 0x27 && self.version <= 0x29 else {
			throw SteamAppInfoError.unsupported
		}

		guard let universe = SteamUniverse(rawValue: Int(try cursor.read(as: UInt32.self))) else {
			throw SteamAppInfoError.unsupported
		}

		self.universe = universe

		var stringTable: [ValveKeyValueNode]? = nil
		if version >= 0x29 {
			let stringTableCursor = DataCursor(data)
			stringTableCursor.index = Data.Index(try cursor.read(as: UInt64.self))

			let stringCount = Int(try stringTableCursor.read(as: UInt32.self))
			var table: [ValveKeyValueNode] = []
			for _ in 0...stringCount - 1 {
				table.append(ValveKeyValueNode(try stringTableCursor.readUtf8String()))
			}
			stringTable = table
		}

		var apps: [SteamAppData] = []
		while let app = try SteamAppData(version: self.version, data: cursor, stringTable: stringTable) {
			apps.append(app)
		}
		self.apps = apps
	}
}
