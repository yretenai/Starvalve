// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Starvalve

struct List: ParsableCommand {
	@OptionGroup var globals: GlobalOptions

	mutating func run() {
	}
}
