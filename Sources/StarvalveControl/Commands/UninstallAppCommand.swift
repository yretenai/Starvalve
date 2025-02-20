// SPDX-FileCopyrightText: 2024-2025 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Foundation
import Starvalve

struct UninstallAppCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "uninstall",
		abstract: "Uninstall a game without running uninstall scripts."
	)

	@OptionGroup var volatile: VolatileOptions

	@OptionGroup var globals: GlobalOptions

	func run() {
		var steam = SteamHelper(steamPath: globals.steamPath)

		guard let libraries = steam.libraryFolders else {
			print("⚠️ Steam libraries failed to parse.")
			return
		}

		guard libraries.entries.count > 0 else {
			print("⚠️ Need at least one additional steam library")
			return
		}
	}
}
