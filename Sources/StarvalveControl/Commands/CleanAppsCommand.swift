// SPDX-FileCopyrightText: 2024-2025 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Foundation
import Starvalve

struct CleanAppsCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "clean",
		abstract: "Remove leftover directories and linux-specific cache files from game directories",
		discussion: """
			Removes stray installation directories that are not referenced.
			You can cause an app to be skipped by making an (empty) ".starvalvekeep" file in the installation directory.
			It is encouraged to try a dry run first (--dry).
			Additionally on Linux it removes .dkvk-cache files.
			"""
	)

	@OptionGroup var volatile: VolatileOptions

	@OptionGroup var globals: GlobalOptions

	func run() {
		let steam = SteamHelper(steamPath: globals.steamPath)

		guard let libraries = steam.libraryFolders else {
			print("⚠️ Steam libraries failed to parse.")
			return
		}

		for library in libraries.entries {
			var knownPaths: Set<String> = []

			let knownAppIds = Set(
				steam.shortcuts.flatMap({ (_, value) in
					value.entries
				}).map({ shortcut in
					shortcut.appID
				}) + library.apps.keys)

			for (appId, _) in library.apps {
				let appInfo = AppInfo(libraryPath: library.path, appId: appId, detailed: false)

				guard !appInfo.missingManifest else {
					continue
				}

				knownPaths.insert(library.path.appending(path: "common/\(appInfo.acf.installDir)", directoryHint: .isDirectory).canonicalPath.path)
			}

			if let libraryContents = try? FileManager.default.contentsOfDirectory(at: library.path.appending(path: "common", directoryHint: .isDirectory), includingPropertiesForKeys: nil) {
				for strayPath in libraryContents.filter({ url in
					url.isDirectory && !knownPaths.contains(url.canonicalPath.path)
				}).map({ url in
					url.canonicalPath
				}) {
					if FileManager.default.fileExists(atPath: strayPath.appending(path: ".starvalvekeep").path) {
						continue
					}

					if volatile.interactive {
						print("Delete \"\(strayPath.path, color: .red)\"? [Y/n]:", terminator: " ")
						guard let line = readLine(strippingNewline: true),
							let firstChar = line.lowercased().first,
							firstChar == "y"
						else {
							continue
						}
					}

					print("⚠️ Deleting leftover install directory \(strayPath.path, color: .red)")

					guard !volatile.dry else {
						continue
					}

					guard (try? FileManager.default.removeItem(at: strayPath)) != nil else {
						print("⚠️ Could not delete directory")
						continue
					}
				}
			}

			let shaderContents = (try? FileManager.default.contentsOfDirectory(at: library.path.appending(path: "shadercache", directoryHint: .isDirectory), includingPropertiesForKeys: nil)) ?? []
			let compatContents = (try? FileManager.default.contentsOfDirectory(at: library.path.appending(path: "compatdata", directoryHint: .isDirectory), includingPropertiesForKeys: nil)) ?? []

			for appPath in shaderContents + compatContents {
				guard let appId = UInt(appPath.lastPathComponent, radix: 10),
					!knownAppIds.contains(appId)
				else {
					continue
				}

				if volatile.interactive {
					print("Delete \"\(appPath.path, color: .red)\"? [Y/n]:", terminator: " ")
					guard let line = readLine(strippingNewline: true),
						let firstChar = line.lowercased().first,
						firstChar == "y"
					else {
						continue
					}
				}

				print("⚠️ Deleting leftover support directory \(appPath.path, color: .red)")

				guard !volatile.dry else {
					continue
				}

				guard (try? FileManager.default.removeItem(at: appPath)) != nil else {
					print("⚠️ Could not delete directory")
					continue
				}
			}
		}

	}
}
