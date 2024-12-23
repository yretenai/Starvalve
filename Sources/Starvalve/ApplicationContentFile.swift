// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

/// All possible state values for installed apps.
public struct ACFAppState: OptionSet, Sendable, Hashable, CustomStringConvertible {
	public let rawValue: UInt

	/// a textual representation of this option set.
	public var description: String {
		let filtered = ACFAppState.descriptors.filter { element in
			self.contains(element.key)
		}

		if filtered.isEmpty {
			return "none"
		}

		return filtered.values.joined(separator: ", ")
	}

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

	static private let descriptors: [Self: String] = [
		.uninstalled: "uninstalled",
		.updateRequired: "update required",
		.fullyInstalled: "fully installed",
		.updateQueued: "update queued",
		.updateOptional: "update optional",
		.filesMissing: "missing",
		.sharedOnly: "shared only",
		.filesCorrupt: "corrupt",
		.updateRunning: "update running",
		.updatePaused: "update paused",
		.updateStarted: "update started",
		.uninstalling: "uninstalling",
		.backupRunning: "backup running",
		.appRunning: "app running",
		.componentInUse: "component in use",
		.movingFolder: "moving folder",
		.updateHidden: "update hidden",
		.prefetchingInfo: "prefetching info",
	]

	public init(rawValue: UInt) {
		self.rawValue = rawValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(rawValue)
	}
}

/// Whether or not an update recently succeeded.
public enum ACFUpdateResult: UInt, CustomStringConvertible {
	case failure
	case success

	/// a textual representation of this enum.
	public var description: String {
		switch self {
			case .failure: "success"
			case .success: "failure"
		}
	}
}

/// Determines how Steam should auto update games.
public enum ACFAutoUpdateBehavior: UInt, CustomStringConvertible {
	case automatic
	case beforeStart
	case highPriority

	/// a textual representation of this enum.
	public var description: String {
		switch self {
			case .automatic: "automatic"
			case .beforeStart: "before app start"
			case .highPriority: "high priority"
		}
	}
}

/// Determines if Steam should allow background updates.
public enum ACFBackgroundUpdateBehavior: UInt, CustomStringConvertible {
	case deferToGlobalSetting
	case allow
	case disallow

	/// a textual representation of this enum.
	public var description: String {
		switch self {
			case .deferToGlobalSetting: "defer to global setting"
			case .allow: "allow"
			case .disallow: "disallow"
		}
	}
}

/// An installed depot with it's manifest and size.
public struct ACFInstalledApplicationDepot: VDFContent {
	public let depotId: UInt
	public var manifest: UInt = 0
	public var size: UInt = 0

	public init(depotId: UInt) {
		self.depotId = depotId
	}

	public init?(vdf: ValveKeyValue) {
		depotId = vdf.key.unsigned ?? 0
		manifest = vdf["Manifest"]?.unsigned ?? 0
		size = vdf["Size"]?.unsigned ?? 0
	}

	public func vdf() -> ValveKeyValue {
		let vdf = ValveKeyValue(ValveKeyValueNode(unsigned: depotId))
		vdf["manifest"] = ValveKeyValueNode(unsigned: manifest)
		vdf["size"] = ValveKeyValueNode(unsigned: size)
		return vdf
	}
}

/// Determines what kind of ACF manifest this is.
public enum ACFType: String {
	case appState = "AppState"
	case appWorkshop = "AppWorkshop"
}

/// Minimal data for workshop items, used to mark one as installed.
public class ACFWorkshopItem: VDFContent {
	public let ugcId: UInt
	public var size: UInt = 0
	public var timeUpdated: Date = Date(timeIntervalSince1970: 0)
	public var manifest: Int = -1
	public var ugcHandle: UInt = 0

	public init(ugcId: UInt) {
		self.ugcId = ugcId
	}

	public required init?(vdf: ValveKeyValue) {
		ugcId = vdf.key.unsigned ?? 0
		size = vdf["Size"]?.unsigned ?? 0
		timeUpdated = vdf["TimeUpdated"]?.date ?? Date(timeIntervalSince1970: 0)
		manifest = vdf["Manifest"]?.signed ?? -1
		ugcHandle = vdf["UGCHandle"]?.unsigned ?? 0
	}

	public func vdf() -> ValveKeyValue {
		let vdf = ValveKeyValue(ValveKeyValueNode(unsigned: ugcId))
		vdf["size"] = ValveKeyValueNode(unsigned: size)
		vdf["timeupdated"] = ValveKeyValueNode(epoch: timeUpdated)
		vdf["manifest"] = ValveKeyValueNode(signed: manifest)
		vdf["ugchandle"] = ValveKeyValueNode(unsigned: ugcHandle)
		return vdf
	}
}

/// Detailed data for workshop items.
public class ACFWorkshopItemDetails: ACFWorkshopItem {
	public var timeTouched: Date = Date(timeIntervalSince1970: 0)
	public var latestTimeUpdated: Date = Date(timeIntervalSince1970: 0)
	public var subscribedBy: SteamID = SteamID(accountID: 0)
	public var latestManifest: Int = -1

	public required init?(vdf: ValveKeyValue) {
		super.init(vdf: vdf)
		timeTouched = vdf["TimeTouched"]?.date ?? Date(timeIntervalSince1970: 0)
		latestTimeUpdated = vdf["Latest_TimeUpdated"]?.date ?? Date(timeIntervalSince1970: 0)
		subscribedBy = SteamID(accountID: vdf["SubscribedBy"]?.unsigned ?? 0)
		manifest = vdf["Latest_Manifest"]?.signed ?? -1
	}

	public override func vdf() -> ValveKeyValue {
		let vdf = super.vdf()
		vdf["timetouched"] = ValveKeyValueNode(epoch: timeTouched)
		vdf["latest_timeupdated"] = ValveKeyValueNode(epoch: latestTimeUpdated)
		vdf["subscribedby"] = ValveKeyValueNode(unsigned: subscribedBy.accountID)
		vdf["latest_manifest"] = ValveKeyValueNode(signed: latestManifest)
		return vdf
	}
}

/// ACF file format structure.
public struct ApplicationContentFile: VDFContent {
	public let type: ACFType
	public var appId: UInt = 0
	public var universe: SteamUniverse = .steam
	public var name: String = ""
	public var stateFlags: ACFAppState = []
	public var installDir: String = ""
	public var lastUpdated: Date = Date(timeIntervalSince1970: 0)
	public var lastPlayed: Date = Date(timeIntervalSince1970: 0)
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
	public var scheduledAutoUpdate: Date = Date(timeIntervalSince1970: 0)
	public var stagingFolder: Int?  // index of library folder in libraryfolders.vdf
	public var needsUpdate: Bool = false
	public var needsDownload: Bool = false
	public var installedDepots: [UInt: ACFInstalledApplicationDepot] = [:]
	public var sharedDepots: [UInt: UInt] = [:]
	public var installScripts: [UInt: String] = [:]
	public var userConfig: [String: ValveKeyValue] = [:]
	public var mountedConfig: [String: ValveKeyValue] = [:]
	public var workshopItems: [UInt: ACFWorkshopItem] = [:]
	public var workshopItemDetails: [UInt: ACFWorkshopItemDetails] = [:]

	public init(type: ACFType) {
		self.type = type
	}

	public init?(vdf: ValveKeyValue) {
		guard let type = ACFType(rawValue: vdf.key.string ?? "") else {
			return nil
		}

		self.type = type

		guard let appId = vdf["AppId"]?.unsigned else {
			return nil
		}

		self.appId = appId

		//state
		universe = SteamUniverse(rawValue: vdf["universe"]?.signed ?? 0) ?? .invalid
		name = String(describing: vdf["Name"]?.string ?? "SteamApp\(appId)")
		stateFlags = ACFAppState(rawValue: vdf["StateFlags"]?.unsigned ?? 0)
		installDir = String(describing: vdf["InstallDir"]?.string ?? "SteamApp")
		lastUpdated = vdf["LastUpdated"]?.date ?? vdf["TimeLastUpdated"]?.date ?? Date(timeIntervalSince1970: 0)
		lastPlayed = vdf["LastPlayed"]?.date ?? vdf["TimeLastAppRan"]?.date ?? Date(timeIntervalSince1970: 0)
		sizeOnDisk = vdf["SizeOnDisk"]?.unsigned ?? 0
		stagingSize = vdf["StagingSize"]?.unsigned ?? 0
		buildID = vdf["BuildID"]?.unsigned ?? vdf["LastBuildID"]?.unsigned ?? 0
		lastOwner = SteamID(rawValue: vdf["LastOwner"]?.unsigned ?? 0)
		updateResult = ACFUpdateResult(rawValue: vdf["UpdateResult"]?.unsigned ?? 0) ?? .success
		bytesToDownload = vdf["BytesToDownload"]?.unsigned ?? 0
		bytesDownloaded = vdf["BytesDownloaded"]?.unsigned ?? 0
		bytesToStage = vdf["BytesToStage"]?.unsigned ?? 0
		bytesStaged = vdf["BytesStaged"]?.unsigned ?? 0
		targetBuildID = vdf["TargetBuildID"]?.unsigned ?? 0
		autoUpdateBehavior = ACFAutoUpdateBehavior(rawValue: vdf["AutoUpdateBehavior"]?.unsigned ?? 0) ?? .automatic
		allowOtherDownloadsWhileRunning = ACFBackgroundUpdateBehavior(rawValue: vdf["AllowOtherDownloadsWhileRunning"]?.unsigned ?? 0) ?? .deferToGlobalSetting
		scheduledAutoUpdate = vdf["ScheduledAutoUpdate"]?.date ?? Date(timeIntervalSince1970: 0)
		stagingFolder = vdf["StagingFolder"]?.signed
		installedDepots = vdf["InstalledDepots"]?.to(key: UInt.self, value: ACFInstalledApplicationDepot.self) ?? [:]
		installScripts = vdf["InstallScripts"]?.to(key: UInt.self, value: String.self) ?? [:]
		sharedDepots = vdf["SharedDepots"]?.to(key: UInt.self, value: UInt.self) ?? [:]
		userConfig = vdf["UserConfig"]?.to(key: String.self, value: ValveKeyValue.self) ?? [:]
		mountedConfig = vdf["MountedConfig"]?.to(key: String.self, value: ValveKeyValue.self) ?? [:]

		// workshop
		if vdf["NeedsUpdate"]?.bool ?? false {
			stateFlags.insert(.updateRequired)
		}

		if vdf["NeedsDownload"]?.bool ?? false {
			stateFlags.insert(.filesMissing)
		}

		workshopItems = vdf["WorkshopItemsInstalled"]?.to(key: UInt.self, value: ACFWorkshopItem.self) ?? [:]
		workshopItemDetails = vdf["WorkshopItemDetails"]?.to(key: UInt.self, value: ACFWorkshopItemDetails.self) ?? [:]
	}

	public func vdf() -> ValveKeyValue {
		switch type {
			case .appState: return appStateVdf()
			case .appWorkshop: return appWorkshopVdf()
		}
	}

	private func appWorkshopVdf() -> ValveKeyValue {
		let vdf = ValveKeyValue("AppWorkshop")

		vdf["appid"] = ValveKeyValueNode(unsigned: appId)
		vdf["SizeOnDisk"] = ValveKeyValueNode(unsigned: sizeOnDisk)
		vdf["NeedsUpdate"] = ValveKeyValueNode(bool: stateFlags.contains(.updateRequired))
		vdf["NeedsDownload"] = ValveKeyValueNode(bool: stateFlags.contains(.filesMissing))
		vdf["TimeLastUpdated"] = ValveKeyValueNode(epoch: lastUpdated)
		vdf["TimeLastAppRan"] = ValveKeyValueNode(epoch: lastPlayed)
		vdf.append(ValveKeyValue(key: "WorkshopItemsInstalled", map: workshopItems))
		vdf.append(ValveKeyValue(key: "WorkshopItemDetails", map: workshopItemDetails))

		return vdf
	}

	private func appStateVdf() -> ValveKeyValue {
		let vdf = ValveKeyValue("AppState")

		vdf["appid"] = ValveKeyValueNode(unsigned: appId)
		vdf["universe"] = ValveKeyValueNode(signed: universe.rawValue)
		vdf["name"] = ValveKeyValueNode(name)
		vdf["stateFlags"] = ValveKeyValueNode(unsigned: stateFlags.rawValue)
		vdf["installdir"] = ValveKeyValueNode(installDir)
		vdf["LastUpdated"] = ValveKeyValueNode(epoch: lastUpdated)
		vdf["LastPlayed"] = ValveKeyValueNode(epoch: lastPlayed)
		vdf["SizeOnDisk"] = ValveKeyValueNode(unsigned: sizeOnDisk)
		vdf["StagingSize"] = ValveKeyValueNode(unsigned: stagingSize)
		vdf["buildid"] = ValveKeyValueNode(unsigned: buildID)
		vdf["LastOwner"] = ValveKeyValueNode(unsigned: lastOwner.rawValue)
		vdf["UpdateResult"] = ValveKeyValueNode(unsigned: updateResult.rawValue)
		vdf["BytesToDownload"] = ValveKeyValueNode(unsigned: bytesToDownload)
		vdf["BytesDownloaded"] = ValveKeyValueNode(unsigned: bytesDownloaded)
		vdf["BytesToStage"] = ValveKeyValueNode(unsigned: bytesToStage)
		vdf["BytesStaged"] = ValveKeyValueNode(unsigned: bytesStaged)
		vdf["TargetBuildID"] = ValveKeyValueNode(unsigned: targetBuildID)
		vdf["AutoUpdateBehavior"] = ValveKeyValueNode(unsigned: autoUpdateBehavior.rawValue)
		vdf["AllowOtherDownloadsWhileRunning"] = ValveKeyValueNode(unsigned: allowOtherDownloadsWhileRunning.rawValue)
		vdf["ScheduledAutoUpdate"] = ValveKeyValueNode(epoch: scheduledAutoUpdate)

		if let stagingFolder = stagingFolder {
			vdf["StagingFolder"] = ValveKeyValueNode(signed: stagingFolder)
		}

		vdf.append(ValveKeyValue(key: "InstalledDepots", map: installedDepots))

		if !self.installScripts.isEmpty {
			vdf.append(ValveKeyValue(key: "InstallScripts", map: installScripts))
		}

		if !self.sharedDepots.isEmpty {
			vdf.append(ValveKeyValue(key: "SharedDepots", map: sharedDepots))
		}

		vdf.append(ValveKeyValue(key: "UserConfig", map: userConfig))
		vdf.append(ValveKeyValue(key: "MountedConfig", map: mountedConfig))

		return vdf
	}
}
