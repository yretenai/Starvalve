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

		if count == 0 {
			return Data()
		}

		let value = data[index...(index + count - 1)]
		guard value.count == count else {
			throw DataCursorError.outOfBounds
		}

		index = index + count
		return value
	}

	func readUtf8String() throws -> String {
		guard index >= 0 else {
			throw DataCursorError.outOfBounds
		}

		let size = data[index...].firstIndex { byte in
			byte == 0
		}

		guard var size = size else {
			throw DataCursorError.nonNullTerminatedString
		}

		size = size - index

		guard size > 0 else {
			index = index + 1
			return ""
		}

		let bytes = try readBytes(count: size)
		let result = bytes.withUnsafeBytes { rawPointer in
			let ptr = rawPointer.assumingMemoryBound(to: UTF8.CodeUnit.self)
			return String.decodeCString(ptr.baseAddress, as: UTF8.self, repairingInvalidCodeUnits: true)
		}

		guard let result = result else {
			throw DataCursorError.nonNullTerminatedString
		}

		index = index + 1

		return result.result
	}

	private func getUtf16StringLength() -> Int? {
		for i in stride(from: 0, to: data.count, by: 2) {
			let word = UInt16(data[i]) | (UInt16(data[i + 1]) << 8)
			if word == 0x0000 {
				return i
			}
		}

		return nil
	}

	func readUtf16String() throws -> String {
		guard index >= 0 else {
			throw DataCursorError.outOfBounds
		}

		let size = getUtf16StringLength()

		guard let size = size else {
			throw DataCursorError.nonNullTerminatedString
		}

		if size == 0 {
			return ""
		}

		let bytes = try readBytes(count: size)
		let result = bytes.withUnsafeBytes { rawPointer in
			let ptr = rawPointer.assumingMemoryBound(to: UTF16.CodeUnit.self)
			return String.decodeCString(ptr.baseAddress, as: UTF16.self, repairingInvalidCodeUnits: true)
		}

		guard let result = result else {
			throw DataCursorError.nonNullTerminatedString
		}

		index = index + 2

		return result.result
	}

	func read() throws -> UInt8 {
		guard index >= 0 else {
			throw DataCursorError.outOfBounds
		}

		guard index + 1 <= data.count else {
			throw DataCursorError.outOfBounds
		}

		let value = data[index]

		index = index + 1

		return value
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
			return rawBuffer.loadUnaligned(fromByteOffset: index, as: type)
		}

		index = index + size

		return value
	}
}
