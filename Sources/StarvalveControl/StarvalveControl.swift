// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser

@main
struct StarvalveControl: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "starvalvectl",
		abstract: "A utility for manipulating Steam installations.",
		subcommands: [ListAppsCommand.self, LibrariesCommand.self, StagingCommand.self],
		defaultSubcommand: ListAppsCommand.self
	)
}
