// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Starvalve

struct ListAppsCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "list",
		abstract: "Lists installed Steam apps"
	)

	@OptionGroup var globals: GlobalOptions

	mutating func run() {
	}
}
