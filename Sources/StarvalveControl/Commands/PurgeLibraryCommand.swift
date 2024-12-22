// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Foundation
import Starvalve

struct PurgeLibraryCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "purge",
		abstract: "Removes the Steam Library and updates staging directories."
	)

	@Argument(help: "The path of the library to remove.", completion: .directory)
	var path: URL

	@Option(help: "The staging library to use for any libraries that rely on the specified library.", completion: .directory)
	var stagingPath: URL?

	@OptionGroup var globals: GlobalOptions

	func run() {
		var steam = SteamHelper(steamPath: globals.steamPath)

		guard let libraries = steam.libraryFolders else {
			preconditionFailure("Steam libraries failed to parse.")
		}

		let target = path.canonicalPath.path
		let stagingTarget = stagingPath?.canonicalPath.path
		var index: Int?
		var selectedIndex: Int?

		for libraryIndex in 0...libraries.entries.count - 1 {
			let library = libraries.entries[libraryIndex]
			let libraryPath = library.path.canonicalPath.path
			if libraryPath == target && index == nil {
				index = libraryIndex
			}

			if libraryPath == stagingTarget {
				selectedIndex = libraryIndex
			}
		}

		guard let index = index else {
			print("could not find library path \(target, color: .red)")
			return
		}

		libraries.entries.remove(at: index)

		// for library in libraries.entries {
		// 	for (appId, _) in library.apps {
		// 		guard let appInfo = AppInfo(libraryPath: library.path, appId: appId) else {
		// 			continue
		// 		}

		// 		var acf = appInfo.acf
		// 		guard var stagingIndex = acf.stagingFolder else {
		// 			continue
		// 		}

		// 		if stagingIndex == index {
		// 			stagingIndex = selectedIndex ?? 0
		// 			print("updated staging folder for app \(acf.name)")
		// 		} else if stagingIndex > index {
		// 			stagingIndex -= 1
		// 			print("adjusted staging folder for app \(acf.name)")
		// 		} else {
		// 			continue
		// 		}

		// 		acf.stagingFolder = stagingIndex

		// 		guard let _ = try? TextVDF.write(url: appInfo.acfPath, vdf: acf.vdf()) else {
		// 			print("could not write file for appmanifest \(acf.name)")
		// 			continue
		// 		}
		// 	}
		// }

		// todo: delete folder if it exists?

		steam.libraryFolders = libraries
	}
}
