// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Foundation
import Starvalve

struct LibraryLabelCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "label",
		abstract: "Updates the label for Steam Libraries."
	)

	@Argument(help: "The path of the library to update.", completion: .directory)
	var path: URL

	@Argument(help: "The label to apply to the library.")
	var label: String? = nil

	@OptionGroup var globals: GlobalOptions

	func run() {
		var steam = SteamHelper(steamPath: globals.steamPath)

		guard let libraries = steam.libraryFolders else {
			preconditionFailure("Steam libraries failed to parse.")
		}

		let target = path.canonicalPath.path

		for library in libraries.entries {
			if library.path.canonicalPath.path == target {
				library.label = label ?? ""
				try? TextVDF.write(url: library.path.appending(path: "libraryfolder.vdf", directoryHint: .notDirectory), vdf: library.singleVdf())
				steam.libraryFolders = libraries
				print("set library the label of \(library.path.path, color: .green) to \"\(label ?? "", color: .green)\"")
				return
			}
		}

		print("could not find library library \(target, color: .red)")
	}
}
