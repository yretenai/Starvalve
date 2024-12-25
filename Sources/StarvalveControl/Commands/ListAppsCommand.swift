// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Foundation
import Starvalve

struct ListAppsCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "list",
		abstract: "Lists installed Steam apps"
	)

	@Flag(help: "Print detailed app information")
	var detailed: Bool = false

	@Argument(help: "App ids to process")
	var appIds: [UInt] = []

	@OptionGroup var globals: GlobalOptions

	func run() {
		let steam = SteamHelper(steamPath: globals.steamPath)

		guard let libraries = steam.libraryFolders else {
			print("⚠️ Steam libraries failed to parse.")
			return
		}

		let users = steam.users
		var appConfig: [UInt: [SteamID: ValveKeyValue]] = [:]
		for (key, value) in steam.localConfig {
			guard let vdf = value["Software"]?["Valve"]?["Steam"]?["Apps"] else {
				continue
			}

			for element in vdf {
				guard let appID = element.key.signed else {
					continue
				}

				let unsignedAppID = appID < 0 ? 0xFFFF_FFFF - UInt(~appID) : UInt(appID)
				if var userAppConfig = appConfig[unsignedAppID] {
					userAppConfig[key] = element
				} else {
					appConfig[unsignedAppID] = [key: element]
				}
			}
		}

		var strayPaths: [String] = []

		guard let primaryLibrary = libraries.entries.first else {
			return
		}

		for library in libraries.entries {
			var knownPaths: Set<String> = []

			let filteredAppIds =
				self.appIds.isEmpty
				? library.apps
				: library.apps.filter({ item in
					self.appIds.contains(item.key)
				})

			for (appId, appSize) in filteredAppIds {
				let appInfo = AppInfo(libraryPath: library.path, appId: appId, detailed: detailed)

				guard !appInfo.missingManifest else {
					print("⚠️ app \(appId, color: .magenta) has a missing manifest")
					continue
				}

				print("app \(appInfo.acf.name, color: .green) (\(appId, color: .magenta))")

				guard detailed else {
					continue
				}

				knownPaths.insert(library.path.appending(path: "common/\(appInfo.acf.installDir)", directoryHint: .isDirectory).canonicalPath.path)

				print("\tsize: \(appSize.formatted(.byteCount(style: .binary)).lowercased(), color: .yellow)")

				if let workshop = appInfo.workshop, workshop.sizeOnDisk > 0 {
					print("\tworkshop: \(workshop.sizeOnDisk.formatted(.byteCount(style: .binary)).lowercased(), color: .yellow)")
				}

				if appInfo.compatDataSize > 0 {
					print("\tcompatdata: \(appInfo.compatDataSize.formatted(.byteCount(style: .binary)).lowercased(), color: .yellow)")
				}

				if appInfo.shaderCacheSize > 0 {
					print("\tshadercache: \(appInfo.shaderCacheSize.formatted(.byteCount(style: .binary)).lowercased(), color: .yellow)")
				}

				print("\tstate: \(appInfo.acf.stateFlags, color: .cyan)")
				print("\tinstall dir: \(appInfo.acf.installDir, color: .green)")
				print("\tlast played: \(appInfo.acf.lastPlayed.nowOrNever, color: .blue)")
				print("\tlast updated: \(appInfo.acf.lastUpdated.nowOrNever, color: .blue)")
				print("\tscheduled update time: \(appInfo.acf.scheduledAutoUpdate.nowOrNever, color: .blue)")
				print("\tbuild id: \(appInfo.acf.buildID, color: .magenta)")
				print("\ttarget build id: \(appInfo.acf.targetBuildID, color: .magenta)")

				if appInfo.acf.lastOwner.rawValue != 0 {
					print("\tlast owner: \(users[appInfo.acf.lastOwner] ?? appInfo.acf.lastOwner.steam3, color: .green) (\(appInfo.acf.lastOwner, color: .red))")
				}

				print("\tbytes to download: \(appInfo.acf.bytesToDownload.formatted(.byteCount(style: .binary)).lowercased(), color: .yellow)")
				print("\tbytes to stage: \(appInfo.acf.bytesToStage.formatted(.byteCount(style: .binary)).lowercased(), color: .yellow)")
				print("\tbytes downloaded: \(appInfo.acf.bytesDownloaded.formatted(.byteCount(style: .binary)).lowercased(), color: .yellow)")
				print("\tbytes staged: \(appInfo.acf.bytesStaged.formatted(.byteCount(style: .binary)).lowercased(), color: .yellow)")
				print("\tupdate result: \(appInfo.acf.updateResult, color: .cyan)")
				print("\tupdate behavior: \(appInfo.acf.autoUpdateBehavior, color: .cyan)")
				print("\tbackground behavior: \(appInfo.acf.allowOtherDownloadsWhileRunning, color: .cyan)")
				if let stagingIndex = appInfo.acf.stagingFolder {
					print("\tstaging library: \(libraries.entries[optionally: stagingIndex]?.path.path ?? "invalid", color: .magenta)")
				}
				print("\tstaging size \(appInfo.acf.stagingSize.formatted(.byteCount(style: .binary)).lowercased(), color: .yellow)")
				if let userInfo = appConfig[appId] {
					print("\tplay stats")
					for (userId, vdf) in userInfo {
						print("\t\t\(users[userId] ?? userId.steam3, color: .green) (\(userId, color: .red))")
						print("\t\tlast played: \((vdf["LastPlayed"]?.date ?? Date(timeIntervalSince1970: 0)).nowOrNever, color: .blue)")
						if let launchArgs = vdf["LaunchOptions"]?.string, !launchArgs.isEmpty {
							print("\t\tlaunch args: \(vdf["LaunchOptions"]?.string ?? "", color: .green)")
						}
						print("\t\tplaytime: \(TimeInterval((vdf["Playtime"]?.unsigned ?? 0) * 60).durationDescription, color: .blue)")
						print()
					}
				}
				print()
			}

			guard let libraryContents = try? FileManager.default.contentsOfDirectory(at: library.path.appending(path: "common", directoryHint: .isDirectory), includingPropertiesForKeys: nil) else {
				continue
			}

			strayPaths.append(
				contentsOf: libraryContents.filter({ url in
					url.isDirectory && !knownPaths.contains(url.canonicalPath.path)
				}).map({ url in
					url.canonicalPath.path
				}))
		}

		for (user, shortcuts) in steam.shortcuts {
			let filteredShortcuts =
				self.appIds.isEmpty
				? shortcuts.entries
				: shortcuts.entries.filter({ item in
					self.appIds.contains(item.appID)
				})

			for shortcut in filteredShortcuts {
				print("shortcut (\(users[user] ?? user.steam3, color: .green) (\(user, color: .red))) \(shortcut.name, color: .green) (\(shortcut.appID, color: .magenta))")

				guard detailed else {
					continue
				}

				let appInfo = AppInfo(libraryPath: primaryLibrary.path, appId: shortcut.appID, detailed: true)

				if appInfo.compatDataSize > 0 {
					print("\tcompatdata: \(appInfo.compatDataSize.formatted(.byteCount(style: .binary)).lowercased(), color: .yellow)")
				}

				if appInfo.shaderCacheSize > 0 {
					print("\tshadercache: \(appInfo.shaderCacheSize.formatted(.byteCount(style: .binary)).lowercased(), color: .yellow)")
				}

				print("\texecutable: \(shortcut.executable, color: .green)")
				print("\tstart in: \(shortcut.startIn.path, color: .green)")
				print("\tlaunch args: \("\"\(shortcut.launchArgs)\"", color: .green)")
				print("\tshortcut path: \(shortcut.shortcutPath.path, color: .green)")
				print("\tlast played: \(shortcut.lastPlayTime.nowOrNever, color: .blue)")
				print("\ticon: \(shortcut.icon.path, color: .green)")
				print("\thidden: \(shortcut.isHidden, color: .cyan)")
				print("\tdesktop: \(shortcut.allowDesktopConfig, color: .cyan)")
				print("\toverlay: \(shortcut.allowOverlay, color: .cyan)")
				print("\topenvr: \(shortcut.isOpenVR, color: .cyan)")
				print("\tdevkit: \(shortcut.isDevkit, color: .cyan)")

				if shortcut.isDevkit {
					print("\tdevkit game id: \(shortcut.devkitAppID, color: .magenta)")
					print("\tdevkit app id: \(shortcut.devkitOverrideAppID, color: .magenta)")
				}

				if !shortcut.flatpakAppID.isEmpty {
					print("\tflatpak: \(shortcut.flatpakAppID, color: .green)")
				}

				if !shortcut.tags.isEmpty {
					let tags = shortcut.tags.map({ tag in
						return "\(tag, color: .green)"
					}).joined(separator: ", ")
					print("\ttags: [\(tags)]")
				}

				if let userInfo = appConfig[shortcut.appID] {
					print("\tplay stats")
					for (userId, vdf) in userInfo {
						print("\t\t\(users[userId] ?? userId.steam3, color: .green) (\(userId, color: .red))")
						print("\t\tlast played: \((vdf["LastPlayed"]?.date ?? Date(timeIntervalSince1970: 0)).nowOrNever, color: .blue)")
						if let launchArgs = vdf["LaunchOptions"]?.string, !launchArgs.isEmpty {
							print("\t\tlaunch args: \(vdf["LaunchOptions"]?.string ?? "", color: .green)")
						}
						print("\t\tplaytime: \(TimeInterval((vdf["Playtime"]?.unsigned ?? 0) * 60).durationDescription, color: .blue)")
						print()
					}
				}

				print()
			}
		}

		for stray in strayPaths {
			print("⚠️ \(stray, color: .green) is leftover uninstall debris")
		}
	}
}
