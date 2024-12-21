// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser

struct GlobalOptions: ParsableCommand {
	@Argument(help: "Path to the steam installation")
	var steamPath: String? = nil
}
