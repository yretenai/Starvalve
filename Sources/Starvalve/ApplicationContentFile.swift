// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

/// All possible state values for installed apps.
public struct ACFAppState: OptionSet, Sendable {
	public let rawValue: UInt

	public static let uninstalled = ACFAppState(rawValue: 0x1)
	public static let updateRequired = ACFAppState(rawValue: 0x2)
	public static let fullyInstalled = ACFAppState(rawValue: 0x4)
	public static let updateQueued = ACFAppState(rawValue: 0x8)
	public static let updateOptional = ACFAppState(rawValue: 0x10)
	public static let filesMissing = ACFAppState(rawValue: 0x20)
	public static let sharedOnly = ACFAppState(rawValue: 0x40)
	public static let filesCorrupt = ACFAppState(rawValue: 0x80)
	public static let updateRunning = ACFAppState(rawValue: 0x100)
	public static let updatePaused = ACFAppState(rawValue: 0x200)
	public static let updateStarted = ACFAppState(rawValue: 0x400)
	public static let uninstalling = ACFAppState(rawValue: 0x800)
	public static let backupRunning = ACFAppState(rawValue: 0x1000)
	public static let appRunning = ACFAppState(rawValue: 0x2000)
	public static let componentInUse = ACFAppState(rawValue: 0x4000)
	public static let movingFolder = ACFAppState(rawValue: 0x8000)
	public static let updateHidden = ACFAppState(rawValue: 0x10000)
	public static let prefetchingInfo = ACFAppState(rawValue: 0x20000)

	public init(rawValue: UInt) {
		self.rawValue = rawValue
	}
}

/// Whether or not an update recently succeeded.
public enum ACFUpdateResult: UInt {
	case success
	case failure
}

/// Determines how Steam should auto update games.
public enum ACFAutoUpdateBehavior: UInt {
	case automatic
	case beforeStart
	case highPriority
}

/// Determines if Steam should allow background updates.
public enum ACFBackgroundUpdateBehavior: UInt {
	case deferToGlobalSetting
	case allow
	case disallow
}

/// An installed depot with it's manifest and size.
public struct ACFInstalledApplicationDepot: VDFContent {
	public let depotId: UInt
	public var manifest: UInt
	public var size: UInt

	public init(depotId: UInt, manifest: UInt, size: UInt) {
		self.depotId = depotId
		self.manifest = manifest
		self.size = size
	}

	public init?(vdf: ValveKeyValue) {
		depotId = vdf.key.unsigned ?? 0
		manifest = vdf["Manifest"]?.unsigned ?? 0
		size = vdf["Size"]?.unsigned ?? 0
	}

	public func vdf() -> ValveKeyValue {
		let vdf = ValveKeyValue(ValveKeyValueNode(unsigned: depotId))
		vdf[ValveKeyValueNode("manifest")] = ValveKeyValueNode(unsigned: manifest)
		vdf[ValveKeyValueNode("size")] = ValveKeyValueNode(unsigned: size)
		return vdf
	}
}

/// ACF file format structure.
public struct ApplicationContentFile: VDFContent {
	public var appId: UInt
	public var universe: SteamUniverse = .steam
	public var name: String
	public var stateFlags: ACFAppState = []
	public var installDir: String
	public var lastUpdated: Date = Date.now
	public var lastPlayed: Date = Date(timeIntervalSince1970: TimeInterval(0))
	public var sizeOnDisk: UInt = 0
	public var stagingSize: UInt = 0
	public var buildID: UInt = 0
	public var lastOwner: SteamID = SteamID()
	public var updateResult: ACFUpdateResult = .success
	public var bytesToDownload: UInt = 0
	public var bytesDownloaded: UInt = 0
	public var bytesToStage: UInt = 0
	public var bytesStaged: UInt = 0
	public var targetBuildID: UInt = 0
	public var autoUpdateBehavior: ACFAutoUpdateBehavior = .automatic
	public var allowOtherDownloadsWhileRunning: ACFBackgroundUpdateBehavior = .deferToGlobalSetting
	public var scheduledAutoUpdate: Date = Date(timeIntervalSince1970: TimeInterval(0))
	public var stagingFolder: Int?  // index of library folder in libraryfolders.vdf
	public var installedDepots: [UInt: ACFInstalledApplicationDepot] = [:]
	public var sharedDepots: [UInt: UInt] = [:]
	public var installScripts: [UInt: String] = [:]
	public var userConfig: [String: ValveKeyValue] = [:]
	public var mountedConfig: [String: ValveKeyValue] = [:]

	public init(appId: UInt, name: String, installDir: String? = nil) {
		self.appId = appId
		self.name = name
		self.installDir = installDir ?? name
	}

	public init?(vdf: ValveKeyValue) {
		guard let appId = vdf["AppId"]?.unsigned else {
			return nil
		}

		self.appId = appId
		universe = SteamUniverse(rawValue: vdf["universe"]?.signed ?? 0) ?? .invalid
		name = String(describing: vdf["Name"]?.string ?? "SteamApp\(appId)")
		stateFlags = ACFAppState(rawValue: vdf["StateFlags"]?.unsigned ?? 0)
		installDir = String(describing: vdf["InstallDir"]?.string ?? "SteamApp")
		lastUpdated = Date(timeIntervalSince1970: TimeInterval(vdf["LastUpdated"]?.unsigned ?? 0))
		lastPlayed = Date(timeIntervalSince1970: TimeInterval(vdf["LastPlayed"]?.unsigned ?? 0))
		sizeOnDisk = vdf["SizeOnDisk"]?.unsigned ?? 0
		stagingSize = vdf["StagingSize"]?.unsigned ?? 0
		buildID = vdf["BuildID"]?.unsigned ?? 0
		lastOwner = SteamID(vdf["LastOwner"]?.unsigned ?? 0)
		updateResult = ACFUpdateResult(rawValue: vdf["UpdateResult"]?.unsigned ?? 0) ?? .success
		bytesToDownload = vdf["BytesToDownload"]?.unsigned ?? 0
		bytesDownloaded = vdf["BytesDownloaded"]?.unsigned ?? 0
		bytesToStage = vdf["BytesToStage"]?.unsigned ?? 0
		bytesStaged = vdf["BytesStaged"]?.unsigned ?? 0
		targetBuildID = vdf["TargetBuildID"]?.unsigned ?? 0
		autoUpdateBehavior = ACFAutoUpdateBehavior(rawValue: vdf["AutoUpdateBehavior"]?.unsigned ?? 0) ?? .automatic
		allowOtherDownloadsWhileRunning = ACFBackgroundUpdateBehavior(rawValue: vdf["AllowOtherDownloadsWhileRunning"]?.unsigned ?? 0) ?? .deferToGlobalSetting
		scheduledAutoUpdate = Date(timeIntervalSince1970: TimeInterval(vdf["ScheduledAutoUpdate"]?.unsigned ?? 0))
		stagingFolder = vdf["StagingFolder"]?.signed
		installedDepots = vdf["InstalledDepots"]?.to(key: UInt.self, value: ACFInstalledApplicationDepot.self) ?? [:]
		installScripts = vdf["InstallScripts"]?.to(key: UInt.self, value: String.self) ?? [:]
		sharedDepots = vdf["SharedDepots"]?.to(key: UInt.self, value: UInt.self) ?? [:]
		userConfig = vdf["UserConfig"]?.to(key: String.self, value: ValveKeyValue.self) ?? [:]
		mountedConfig = vdf["MountedConfig"]?.to(key: String.self, value: ValveKeyValue.self) ?? [:]
	}

	public func vdf() -> ValveKeyValue {
		let vdf = ValveKeyValue(ValveKeyValueNode("AppState"))

		vdf[ValveKeyValueNode("appid")] = ValveKeyValueNode(unsigned: appId)
		vdf[ValveKeyValueNode("universe")] = ValveKeyValueNode(signed: universe.rawValue)
		vdf[ValveKeyValueNode("name")] = ValveKeyValueNode(name)
		vdf[ValveKeyValueNode("stateFlags")] = ValveKeyValueNode(unsigned: stateFlags.rawValue)
		vdf[ValveKeyValueNode("installdir")] = ValveKeyValueNode(installDir)
		vdf[ValveKeyValueNode("LastUpdated")] = ValveKeyValueNode(unsigned: UInt(lastUpdated.timeIntervalSince1970))
		vdf[ValveKeyValueNode("LastPlayed")] = ValveKeyValueNode(unsigned: UInt(lastPlayed.timeIntervalSince1970))
		vdf[ValveKeyValueNode("SizeOnDisk")] = ValveKeyValueNode(unsigned: sizeOnDisk)
		vdf[ValveKeyValueNode("StagingSize")] = ValveKeyValueNode(unsigned: stagingSize)
		vdf[ValveKeyValueNode("buildid")] = ValveKeyValueNode(unsigned: buildID)
		vdf[ValveKeyValueNode("LastOwner")] = ValveKeyValueNode(unsigned: lastOwner.rawValue)
		vdf[ValveKeyValueNode("UpdateResult")] = ValveKeyValueNode(unsigned: updateResult.rawValue)
		vdf[ValveKeyValueNode("BytesToDownload")] = ValveKeyValueNode(unsigned: bytesToDownload)
		vdf[ValveKeyValueNode("BytesDownloaded")] = ValveKeyValueNode(unsigned: bytesDownloaded)
		vdf[ValveKeyValueNode("BytesToStage")] = ValveKeyValueNode(unsigned: bytesToStage)
		vdf[ValveKeyValueNode("BytesStaged")] = ValveKeyValueNode(unsigned: bytesStaged)
		vdf[ValveKeyValueNode("TargetBuildID")] = ValveKeyValueNode(unsigned: targetBuildID)
		vdf[ValveKeyValueNode("AutoUpdateBehavior")] = ValveKeyValueNode(unsigned: autoUpdateBehavior.rawValue)
		vdf[ValveKeyValueNode("AllowOtherDownloadsWhileRunning")] = ValveKeyValueNode(unsigned: allowOtherDownloadsWhileRunning.rawValue)
		vdf[ValveKeyValueNode("ScheduledAutoUpdate")] = ValveKeyValueNode(unsigned: UInt(scheduledAutoUpdate.timeIntervalSince1970))

		if let stagingFolder = stagingFolder {
			vdf[ValveKeyValueNode("StagingFolder")] = ValveKeyValueNode(signed: stagingFolder)
		}

		vdf.append(ValveKeyValue(key: ValveKeyValueNode("InstalledDepots"), map: installedDepots))

		if !self.installScripts.isEmpty {
			vdf.append(ValveKeyValue(key: ValveKeyValueNode("InstallScripts"), map: installScripts))
		}

		if !self.sharedDepots.isEmpty {
			vdf.append(ValveKeyValue(key: ValveKeyValueNode("SharedDepots"), map: sharedDepots))
		}

		vdf.append(ValveKeyValue(key: ValveKeyValueNode("UserConfig"), map: userConfig))
		vdf.append(ValveKeyValue(key: ValveKeyValueNode("MountedConfig"), map: mountedConfig))

		return vdf
	}
}
