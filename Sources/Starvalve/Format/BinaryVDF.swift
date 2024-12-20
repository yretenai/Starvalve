// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

enum BinaryVDFToken: UInt8 {
	case startObject = 0
	case utf8String = 1
	case int32 = 2
	case float = 3
	case uint32 = 4
	case utf16String = 5
	case color = 6
	case uint64 = 7
	case closeObject = 8
	case blob = 9
	case int64 = 10
	case closeObject2 = 11

	case invalid = 0xff
}

class BinaryVDFReader {
	private let cursor: DataCursor
	private let stringTable: [ValveKeyValueNode]?
	public let checksum: UInt32

	init(data: DataCursor, stringTable: [ValveKeyValueNode]? = nil) throws {
		cursor = data
		self.stringTable = stringTable

		if try cursor.read(as: UInt32.self) == 0x564B_4256 {
			checksum = try cursor.read(as: UInt32.self)
		} else {
			checksum = 0
			cursor.index -= 4
		}
	}

	func readKey() throws -> ValveKeyValueNode {
		guard let stringTable = stringTable else {
			return ValveKeyValueNode(try cursor.readUtf8String())
		}
		let index = Int(try cursor.read(as: Int32.self))
		if index > stringTable.count {
			throw BinaryVDFError.stringIndexOutOfRange
		}

		return stringTable[index]
	}

	func read() throws -> ValveKeyValue? {
		let token = BinaryVDFToken(rawValue: try cursor.read()) ?? .invalid
		if token == .invalid {
			throw BinaryVDFError.invalidToken
		}

		if token == .closeObject || token == .closeObject2 {
			return nil
		}

		let kv: ValveKeyValue = ValveKeyValue(try readKey())

		switch token {
			case .blob: throw BinaryVDFError.notSupported
			case .float: kv.float = try cursor.read(as: Float32.self)
			case .int32: kv.signed = Int(try cursor.read(as: Int32.self))
			case .color: kv.unsigned = UInt(try cursor.read(as: UInt32.self))
			case .int64: kv.signed = Int(try cursor.read(as: Int64.self))
			case .uint64: kv.unsigned = UInt(try cursor.read(as: UInt64.self))
			case .uint32: kv.unsigned = UInt(try cursor.read(as: UInt32.self))
			case .utf16String: kv.string = try cursor.readUtf16String()
			case .utf8String: kv.string = try cursor.readUtf8String()
			case .startObject:
				while let child = try read() {
					kv.append(child)
				}

			default: break
		}

		return kv
	}
}

/// reader for binary VDF files.
public struct BinaryVDF {
	@available(*, unavailable) private init() {}

	static func read(data: DataCursor, stringTable: [ValveKeyValueNode]? = nil) throws -> ValveKeyValue? {
		let reader = try BinaryVDFReader(data: data, stringTable: stringTable)
		guard let value = try reader.read() else {
			return nil
		}
		data.index = data.index + 1
		return value
	}

	public static func read(data: Data, stringTable: [ValveKeyValueNode]? = nil) throws -> ValveKeyValue? {
		let reader = try BinaryVDFReader(data: DataCursor(data), stringTable: stringTable)
		return try reader.read()
	}
}
