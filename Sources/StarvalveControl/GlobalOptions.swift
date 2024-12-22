// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser

struct GlobalOptions: ParsableCommand {
	@Option(name: .customLong("steam"), help: "Path to the steam installation")
	var steamPath: String? = nil
}
