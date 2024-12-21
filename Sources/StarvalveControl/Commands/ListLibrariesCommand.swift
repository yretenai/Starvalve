// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Foundation
import Starvalve

struct ListLibrariesCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "list",
		abstract: "Lists Steam Libraries"
	)

	@OptionGroup var globals: GlobalOptions

	func run() {
		let steam = SteamHelper(steamPath: globals.steamPath)

		guard let libraries = steam.libraryFolders else {
			preconditionFailure("Steam libraries failed to parse.")
		}

		var appNameMap: [UInt: String] = [:]
		if let appInfo = steam.appInfo {
			for app in appInfo.apps {
				guard let name = app.vdf["common"]?["name"]?.string else {
					continue
				}

				guard !name.isEmpty else {
					continue
				}

				appNameMap[UInt(app.appId)] = name
			}
		}

		for library in libraries.entries {
			print("library \(library.path.path, color: .green)\"")

			if let label = library.label {
				print("label: \(label, color: .default)")
			} else {
				print("label: \("<no label>", color: .red)")
			}

			if FileManager.default.fileExists(atPath: library.path) {
				print("exists: \("yes", color: .green)")
			} else {
				print("exists: \("no", color: .red)")
			}

			print("content id: \(library.contentID, color: .magenta)")
			print("size: \(library.totalSize.formatted(byteBase: .powerOfTwo), color: .yellow)")
			print("update: \(library.updateCleanBytesTally.formatted(byteBase: .powerOfTwo), color: .yellow)")
			print("verification time: \(library.timeLastUpdateVerified.nowOrNever, color: library.timeLastUpdateVerified.timeIntervalSince1970 == 0 ? .red : .green)")
			print("corruption time: \(library.timeLastUpdateCorrpution.nowOrNever, color: library.timeLastUpdateCorrpution.timeIntervalSince1970 == 0 ? .green : .red)")
			print("apps:")
			for (appId, appSize) in library.apps.sorted(by: { left, right in
				left.value > right.value
			}) {
				let appName = appNameMap[appId] ?? "SteamApp\(appId)"
				print("\t\(appName, color: .green) = \(appSize.formatted(byteBase: .powerOfTwo), color: .yellow)")
			}
			print("")
		}
	}
}
