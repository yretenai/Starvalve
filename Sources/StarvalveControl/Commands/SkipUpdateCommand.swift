// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Foundation
import Starvalve

struct SkipUpdateCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "skip",
		abstract: "Skips updates for steam apps"
	)

	@Argument(help: "App ids to process")
	var appIds: [UInt]

	@OptionGroup var globals: GlobalOptions

	func run() {
		let steam = SteamHelper(steamPath: globals.steamPath)

		guard let libraries = steam.libraryFolders else {
			print("⚠️ Steam libraries failed to parse.")
			return
		}

		for library in libraries.entries {
			var appIds = library.apps.sorted(by: { left, right in
				left.value > right.value
			})

			appIds = appIds.filter({ item in
				self.appIds.contains(item.key)
			})

			for (appId, _) in appIds {
				guard let appInfo = AppInfo(libraryPath: library.path, appId: appId) else {
					print("⚠️ app \(appId, color: .magenta) has a missing manifest")
					continue
				}

				var acf = appInfo.acf
				guard acf.stateFlags.contains(.updateRequired) || acf.stateFlags.contains(.updateOptional) else {
					print("app \(acf.name, color: .green) (\(appId, color: .magenta)) does not need to be updated")
					continue
				}

				acf.stateFlags = [.fullyInstalled]
				acf.scheduledAutoUpdate = Date(timeIntervalSince1970: 0)
				acf.buildID = acf.targetBuildID
				acf.targetBuildID = 0
				acf.bytesToDownload = 0
				acf.bytesDownloaded = 0
				acf.bytesToStage = 0
				acf.bytesStaged = 0
				acf.stagingSize = 0
				acf.updateResult = .success

				guard (try? TextVDF.write(url: appInfo.acfPath, vdf: acf.vdf())) != nil else {
					print("⚠️ could not write file for appmanifest \(acf.name)")
					continue
				}

				print("app \(acf.name, color: .green) (\(appId, color: .magenta)) has update state reset")
			}
		}
	}
}
