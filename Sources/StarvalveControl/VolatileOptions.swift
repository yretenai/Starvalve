// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser

struct VolatileOptions: ParsableArguments {
	@Flag(name: [.customShort("n", allowingJoined: true), .long], help: "Don't actually delete files")
	var dry: Bool = false

	@Flag(name: [.customShort("i", allowingJoined: true), .long], help: "Prompt before actually deleting anything")
	var interactive: Bool = false
}
