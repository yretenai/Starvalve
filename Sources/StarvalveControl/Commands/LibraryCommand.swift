// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Starvalve

struct LibrariesCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "library",
		abstract: "Commands relating to Steam libraries",
		subcommands: [ListLibrariesCommand.self],
		defaultSubcommand: ListLibrariesCommand.self
	)
}
