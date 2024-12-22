// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Starvalve

struct StagingCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "staging",
		abstract: "Commands relating to Staging Directories",
		subcommands: [ListStagingLibrariesCommand.self],
		defaultSubcommand: ListStagingLibrariesCommand.self
	)
}
