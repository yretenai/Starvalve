// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

class DataCursor {
	public var data: Data
	public var index: Data.Index

	init(_ data: Data) {
		self.data = data
		index = self.data.startIndex
	}

	func readBytes(count: Int) throws -> Data {
		guard index >= 0 else {
			throw DataCursorError.outOfBounds
		}

		guard count + index <= data.count else {
			throw DataCursorError.outOfBounds
		}

		let value = data[index...(index + count)]
		index = index + count
		return value
	}

	func readAsciiString() throws -> String {
		guard index >= 0 else {
			throw DataCursorError.outOfBounds
		}

		let size = data[index...].firstIndex { byte in
			byte == 0
		}

		guard let size = size else {
			throw DataCursorError.nonNullTerminatedString
		}

		guard let str = String(data: try readBytes(count: size), encoding: .ascii) else {
			throw DataCursorError.nonNullTerminatedString
		}

		index = index + 1

		return str
	}

	func readUnicodeString() throws -> String {
		guard index >= 0 else {
			throw DataCursorError.outOfBounds
		}

		let size = data[index...].firstIndex { byte in
			byte == 0
		}

		guard let size = size else {
			throw DataCursorError.nonNullTerminatedString
		}

		guard let str = String(data: try readBytes(count: size), encoding: .unicode) else {
			throw DataCursorError.nonNullTerminatedString
		}

		index = index + 1

		return str
	}

	func read<T>(as type: T.Type) throws -> T {
		guard index >= 0 else {
			throw DataCursorError.outOfBounds
		}

		let size = MemoryLayout<T>.size
		guard size + index <= data.count else {
			throw DataCursorError.outOfBounds
		}

		let value = data.withUnsafeBytes { rawBuffer in
			return rawBuffer.load(fromByteOffset: index, as: type)
		}

		index = index + size

		return value
	}
}
