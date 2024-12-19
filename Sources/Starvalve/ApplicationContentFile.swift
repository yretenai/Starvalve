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

/// Which platform this game was installed on.
public enum ACFUniverse: Int {
	case invalid
	case steam
	case beta
	case closed
	case dev
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
public struct ACFInstalledApplicationDepot {
	public var manifest: UInt
	public var size: UInt

	public init(manifest: UInt, size: UInt) {
		self.manifest = manifest
		self.size = size
	}

	public init?(_ kv: ValveKeyValue) {
		manifest = kv["Manifest"]?.unsigned ?? 0
		size = kv["Size"]?.unsigned ?? 0
	}

	public func vdf(_ depotId: UInt) -> ValveKeyValue {
		let vdf = ValveKeyValue(ValveKeyValueNode(unsigned: depotId))
		vdf[ValveKeyValueNode("manifest")] = ValveKeyValueNode(unsigned: manifest)
		vdf[ValveKeyValueNode("size")] = ValveKeyValueNode(unsigned: size)
		return vdf
	}
}

/// ACF file format structure.
public struct ApplicationContentFile {
	public var appId: UInt
	public var universe: ACFUniverse = .steam
	public var name: String
	public var stateFlags: ACFAppState = []
	public var installDir: String
	public var lastUpdated: Date = Date.now
	public var lastPlayed: Date = Date(timeIntervalSince1970: TimeInterval(0))
	public var sizeOnDisk: UInt = 0
	public var stagingSize: UInt = 0
	public var buildID: UInt = 0
	public var lastOwner: UInt = 0
	public var updateResult: ACFUpdateResult = .success
	public var bytesToDownload: UInt = 0
	public var bytesDownloaded: UInt = 0
	public var bytesToStage: UInt = 0
	public var bytesStaged: UInt = 0
	public var targetBuildID: UInt = 0
	public var autoUpdateBehavior: ACFAutoUpdateBehavior = .automatic
	public var allowOtherDownloadsWhileRunning: ACFBackgroundUpdateBehavior = .deferToGlobalSetting
	public var scheduledAutoUpdate: Date = Date(timeIntervalSince1970: TimeInterval(0))
	public var stagingFolder: Int?
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

	public init?(_ kv: ValveKeyValue) {
		guard let appId = kv["AppId"]?.unsigned else {
			return nil
		}

		self.appId = appId
		universe = ACFUniverse(rawValue: kv["universe"]?.signed ?? 0) ?? .invalid
		name = String(describing: kv["Name"]?.string ?? "SteamApp\(appId)")
		stateFlags = ACFAppState(rawValue: kv["StateFlags"]?.unsigned ?? 0)
		installDir = String(describing: kv["InstallDir"]?.string ?? "SteamApp")
		lastUpdated = Date(timeIntervalSince1970: TimeInterval(kv["LastUpdated"]?.unsigned ?? 0))
		lastPlayed = Date(timeIntervalSince1970: TimeInterval(kv["LastPlayed"]?.unsigned ?? 0))
		sizeOnDisk = kv["SizeOnDisk"]?.unsigned ?? 0
		stagingSize = kv["StagingSize"]?.unsigned ?? 0
		buildID = kv["BuildID"]?.unsigned ?? 0
		lastOwner = kv["LastOwner"]?.unsigned ?? 0
		updateResult = ACFUpdateResult(rawValue: kv["UpdateResult"]?.unsigned ?? 0) ?? .success
		bytesToDownload = kv["BytesToDownload"]?.unsigned ?? 0
		bytesDownloaded = kv["BytesDownloaded"]?.unsigned ?? 0
		bytesToStage = kv["BytesToStage"]?.unsigned ?? 0
		bytesStaged = kv["BytesStaged"]?.unsigned ?? 0
		targetBuildID = kv["TargetBuildID"]?.unsigned ?? 0
		autoUpdateBehavior = ACFAutoUpdateBehavior(rawValue: kv["AutoUpdateBehavior"]?.unsigned ?? 0) ?? .automatic
		allowOtherDownloadsWhileRunning = ACFBackgroundUpdateBehavior(rawValue: kv["AllowOtherDownloadsWhileRunning"]?.unsigned ?? 0) ?? .deferToGlobalSetting
		scheduledAutoUpdate = Date(timeIntervalSince1970: TimeInterval(kv["ScheduledAutoUpdate"]?.unsigned ?? 0))
		stagingFolder = kv["StagingFolder"]?.signed

		if let installedDepots = kv["InstalledDepots"] {
			for child in installedDepots {
				guard let depotId = child.key.unsigned else {
					continue
				}

				self.installedDepots[depotId] = ACFInstalledApplicationDepot(child)
			}
		}

		if let installScripts = kv["InstallScripts"] {
			for child in installScripts {
				guard let appId = child.key.unsigned else {
					continue
				}

				guard let scriptPath = child.value.string else {
					continue
				}

				self.installScripts[appId] = scriptPath
			}
		}

		if let sharedDepots = kv["SharedDepots"] {
			for child in sharedDepots {
				guard let depotId = child.key.unsigned else {
					continue
				}

				guard let appId = child.unsigned else {
					continue
				}

				self.sharedDepots[depotId] = appId
			}
		}

		if let userConfig = kv["UserConfig"] {
			for child in userConfig {
				guard let key = child.key.string else {
					continue
				}

				self.userConfig[key] = child
			}
		}

		if let mountedConfig = kv["MountedConfig"] {
			for child in mountedConfig {
				guard let key = child.key.string else {
					continue
				}

				self.mountedConfig[key] = child
			}
		}
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
		vdf[ValveKeyValueNode("LastOwner")] = ValveKeyValueNode(unsigned: lastOwner)
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

		let installedDepots = ValveKeyValue(ValveKeyValueNode("InstalledDepots"))
		for (depotId, installedDepot) in self.installedDepots {
			installedDepots.append(installedDepot.vdf(depotId))
		}
		vdf.append(installedDepots)

		if !self.installScripts.isEmpty {
			let installScripts = ValveKeyValue(ValveKeyValueNode("InstallScripts"))
			for (appId, installScript) in self.installScripts {
				installScripts[ValveKeyValueNode(unsigned: appId)] = ValveKeyValueNode(installScript)
			}
			vdf.append(installScripts)
		}

		if !self.sharedDepots.isEmpty {
			let sharedDepots = ValveKeyValue(ValveKeyValueNode("SharedDepots"))
			for (depotId, appId) in self.sharedDepots {
				sharedDepots[ValveKeyValueNode(unsigned: depotId)] = ValveKeyValueNode(unsigned: appId)
			}
			vdf.append(sharedDepots)
		}

		let userConfig = ValveKeyValue(ValveKeyValueNode("UserConfig"))
		for config in self.userConfig.values {
			userConfig.append(config)
		}
		vdf.append(userConfig)

		let mountedConfig = ValveKeyValue(ValveKeyValueNode("MountedConfig"))
		for config: ValveKeyValue in self.mountedConfig.values {
			mountedConfig.append(config)
		}
		vdf.append(mountedConfig)

		return vdf
	}
}
