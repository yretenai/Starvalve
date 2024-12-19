// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

extension Data {
	func read<T>(fromByteOffset offset: Int = 0, as type: T.Type) -> T {
		return withUnsafeBytes { rawBuffer in
			return rawBuffer.load(fromByteOffset: offset, as: type)
		}
	}
}
