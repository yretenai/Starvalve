// SPDX-FileCopyrightText: 2024-2025 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

/// A steam library folder and it's associated metadata.
public class SteamShortcut: VDFContent {
	public let appID: UInt
	public var name: String
	public var executable: String
	public var startIn: URL
	public var launchArgs: String
	public var shortcutPath: URL
	public var icon: URL
	public var isHidden: Bool
	public var allowDesktopConfig: Bool
	public var allowOverlay: Bool
	public var isOpenVR: Bool
	public var isDevkit: Bool
	public var devkitAppID: UInt
	public var devkitOverrideAppID: UInt
	public var lastPlayTime: Date
	public var flatpakAppID: String
	public var tags: [String]

	public required init?(vdf: ValveKeyValue) {
		guard let appID = vdf["AppID"]?.signed else {
			return nil
		}

		guard let appName = vdf["AppName"]?.string else {
			return nil
		}

		self.appID = 0xFFFF_FFFF - UInt(~appID)
		name = appName
		executable = vdf["Exe"]?.string ?? ""
		startIn = URL(filePath: vdf["StartDir"]?.string ?? "", directoryHint: .isDirectory)
		launchArgs = vdf["LaunchOptions"]?.string ?? ""
		shortcutPath = URL(filePath: vdf["ShortcutPath"]?.string ?? "", directoryHint: .notDirectory)
		icon = URL(filePath: vdf["Icon"]?.string ?? "", directoryHint: .notDirectory)
		isHidden = vdf["IsHidden"]?.bool ?? false
		allowDesktopConfig = vdf["AllowDesktopConfig"]?.bool ?? false
		allowOverlay = vdf["AllowOverlay"]?.bool ?? false
		isOpenVR = vdf["OpenVR"]?.bool ?? false
		isDevkit = vdf["Devkit"]?.bool ?? false
		devkitAppID = vdf["DevkitAppId"]?.unsigned ?? 0
		devkitOverrideAppID = vdf["DevkitOverrideAppID"]?.unsigned ?? 0
		lastPlayTime = vdf["LastPlayTime"]?.date ?? Date(timeIntervalSince1970: 0)
		flatpakAppID = vdf["FlatpakAppID"]?.string ?? ""
		tags = vdf["tags"]?.to(sequence: String.self) ?? []
	}

	public func vdf() -> ValveKeyValue {
		let vdf = ValveKeyValue("shortcut")

		vdf["appid"] = ValveKeyValueNode(signed: Int(bitPattern: appID))
		vdf["AppName"] = ValveKeyValueNode(name)
		vdf["Exe"] = ValveKeyValueNode(executable)
		vdf["StartDir"] = ValveKeyValueNode(startIn.path)
		vdf["icon"] = ValveKeyValueNode(icon.path)
		vdf["ShortcutPath"] = ValveKeyValueNode(shortcutPath.path)
		vdf["LaunchOptions"] = ValveKeyValueNode(launchArgs)
		vdf["IsHidden"] = ValveKeyValueNode(bool: isHidden)
		vdf["AllowDesktopConfig"] = ValveKeyValueNode(bool: allowDesktopConfig)
		vdf["AllowOverlay"] = ValveKeyValueNode(bool: allowOverlay)
		vdf["OpenVR"] = ValveKeyValueNode(bool: isOpenVR)
		vdf["Devkit"] = ValveKeyValueNode(bool: isDevkit)
		vdf["DevkitGameID"] = ValveKeyValueNode(unsigned: devkitAppID)
		vdf["DevkitOverrideAppID"] = ValveKeyValueNode(unsigned: devkitOverrideAppID)
		vdf["LastPlayTime"] = ValveKeyValueNode(epoch: lastPlayTime)
		vdf["FlatpakAppID"] = ValveKeyValueNode(flatpakAppID)
		vdf.append(ValveKeyValue(key: "tags", sequence: tags))

		return vdf
	}
}

/// All steam library folders.
public class SteamShortcuts: VDFContent {
	public var entries: [SteamShortcut] = []

	public required init?(vdf: ValveKeyValue) {
		entries = vdf.to(sequence: SteamShortcut.self)
	}

	public func vdf() -> ValveKeyValue {
		ValveKeyValue(key: "shortcuts", sequence: entries)
	}
}
