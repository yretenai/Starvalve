// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser

@main
struct StarvalveControl: ParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "A utility for manipulating Steam installations.",
		subcommands: [List.self],
		defaultSubcommand: List.self
	)
}
