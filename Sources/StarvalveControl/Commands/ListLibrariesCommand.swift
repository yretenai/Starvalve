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

	@Flag(help: "Print detailed app storage usage")
	var detailed: Bool = false

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
			print("library \(library.path.path, color: .green)")

			if let label = library.label {
				print("label: \(label, color: .default)")
			} else {
				print("label: \("<no label>", color: .red)")
			}

			if library.path.isDirectory {
				print("exists: \("yes", color: .green)")
			} else {
				print("exists: \("no", color: .red)")
			}

			print("content id: \(library.contentID, color: .magenta)")
			print("storage size: \(library.totalSize.formatted(.byteCount(style: .file)), color: .yellow)")
			print("size: \(library.appSize.formatted(.byteCount(style: .file)), color: .yellow)")
			print("update: \(library.updateCleanBytesTally.formatted(.byteCount(style: .file)), color: .yellow)")
			print("verification time: \(library.timeLastUpdateVerified.nowOrNever, color: library.timeLastUpdateVerified.timeIntervalSince1970 == 0 ? .red : .green)")
			print("corruption time: \(library.timeLastUpdateCorrpution.nowOrNever, color: library.timeLastUpdateCorrpution.timeIntervalSince1970 == 0 ? .green : .red)")
			if detailed {
				print("apps:")
				for (appId, appSize) in library.apps.sorted(by: { left, right in
					left.value > right.value
				}) {
					let appName = appNameMap[appId] ?? "SteamApp\(appId)"
					print("\tapp \(appName, color: .green)")
					print("\tid: \(appId, color: .magenta)")
					print("\tsize: \(appSize.formatted(.byteCount(style: .file)), color: .yellow)")
					if let appInfo = AppInfo(libraryPath: library.path, appId: appId) {
						if let workshop = appInfo.workshop, workshop.sizeOnDisk > 0 {
							print("\tworkshop: \(workshop.sizeOnDisk.formatted(.byteCount(style: .file)), color: .yellow)")
						}
						if appInfo.compatDataSize > 0 {
							print("\tcompatdata: \(appInfo.compatDataSize.formatted(.byteCount(style: .file)), color: .yellow)")
						}
						if appInfo.shaderCacheSize > 0 {
							print("\tshadercache: \(appInfo.shaderCacheSize.formatted(.byteCount(style: .file)), color: .yellow)")
						}
					} else {
						print("\t⚠️ \("MISSING ACF", color: .red)")
					}
					print()
				}
			}

			if !detailed || library.apps.isEmpty {
				print()
			}
		}
	}
}
