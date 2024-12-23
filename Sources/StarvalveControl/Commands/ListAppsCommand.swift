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
		var strayPaths: [String] = []

		for library in libraries.entries {
			var knownPaths: Set<String> = []

			let filteredAppIds =
				self.appIds.isEmpty
				? library.apps
				: library.apps.filter({ item in
					self.appIds.contains(item.key)
				})

			for (appId, appSize) in filteredAppIds {
				guard let appInfo = AppInfo(libraryPath: library.path, appId: appId, detailed: detailed) else {
					print("⚠️ app \(appId, color: .magenta) has a missing manifest")
					continue
				}

				print("app \(appInfo.acf.name, color: .green) (\(appId, color: .magenta))")

				if !detailed {
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
				print("\tlast played: \(appInfo.acf.lastPlayed, color: .blue)")
				print("\tlast updated: \(appInfo.acf.lastUpdated, color: .blue)")
				print("\tscheduled update time: \(appInfo.acf.scheduledAutoUpdate, color: .blue)")
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

		for stray in strayPaths {
			print("⚠️ \(stray, color: .green) is leftover uninstall debris")
		}
	}
}
