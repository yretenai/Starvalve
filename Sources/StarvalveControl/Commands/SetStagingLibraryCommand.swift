// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Foundation
import Starvalve

struct SetStagingLibraryCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "set",
		abstract: "Sets the staging library for a given app"
	)

	@Argument(help: "The app of the app to update.") var appId: UInt
	@Argument(help: "The path of the library to use as the staging library.", completion: .directory) var library: URL

	@OptionGroup var globals: GlobalOptions

	func run() {
		let steam = SteamHelper(steamPath: globals.steamPath)

		guard let libraries = steam.libraryFolders else {
			print("⚠️ Steam libraries failed to parse.")
			return
		}

		let target = library.canonicalPath.path

		guard
			let index = libraries.entries.firstIndex(where: { library in
				library.path.canonicalPath.path == target
			})
		else {
			print("⚠️ could not find library path \(target, color: .red)")
			return
		}

		for library in libraries.entries {
			for (appId, _) in library.apps {
				guard appId == self.appId else {
					continue
				}

				guard let appInfo = AppInfo(libraryPath: library.path, appId: appId) else {
					continue
				}

				var acf = appInfo.acf

				acf.stagingFolder = libraries.entries.distance(from: libraries.entries.startIndex, to: index)
				guard (try? TextVDF.write(url: appInfo.acfPath, vdf: acf.vdf())) != nil else {
					print("⚠️ could not write file for appmanifest \(acf.name)")
					continue
				}

				print("Set \(acf.name, color: .green) (\(acf.appId, color: .magenta)) staging library to \(library.path.path).")
			}
		}
	}
}
