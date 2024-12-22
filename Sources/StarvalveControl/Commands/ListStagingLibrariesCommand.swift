// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Foundation
import Starvalve

struct ListStagingLibrariesCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "list",
		abstract: "List games with their corresponding staging directories."
	)

	@OptionGroup var globals: GlobalOptions

	func run() {
		let steam = SteamHelper(steamPath: globals.steamPath)

		guard let libraries = steam.libraryFolders else {
			print("⚠️ Steam libraries failed to parse.")
			return
		}

		for library in libraries.entries {
			for (appId, _) in library.apps {
				guard let appInfo = AppInfo(libraryPath: library.path, appId: appId) else {
					continue
				}

				let acf = appInfo.acf
				guard let stagingIndex = acf.stagingFolder else {
					continue
				}

				guard let stagingFolder = libraries.entries[optionally: stagingIndex] else {
					print("⚠️ \(acf.name, color: .green) (\(acf.appId, color: .magenta)) has an invalid staging folder!")
					continue
				}
				print("\(acf.name, color: .green) (\(acf.appId, color: .magenta)) has staging library set to \(stagingFolder.path.path).")
			}
		}
	}
}
