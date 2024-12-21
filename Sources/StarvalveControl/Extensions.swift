// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

enum ByteFormatting: UInt {
	case baseTen = 1000
	case powerOfTwo = 1024
}

enum ASCIIColor: String {
	case black = "\u{001B}[0;30m"
	case red = "\u{001B}[0;31m"
	case green = "\u{001B}[0;32m"
	case yellow = "\u{001B}[0;33m"
	case blue = "\u{001B}[0;34m"
	case magenta = "\u{001B}[0;35m"
	case cyan = "\u{001B}[0;36m"
	case white = "\u{001B}[0;37m"
	case `default` = "\u{001B}[0;0m"
}

extension URL {
	@inlinable var canonicalPath: URL {
		guard let path = try? resourceValues(forKeys: [.canonicalPathKey]).canonicalPath else {
			return self
		}

		return URL(filePath: path)
	}

	@inlinable var isDirectory: Bool {
		(try? resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
	}

	@inlinable var isFile: Bool {
		(try? resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
	}

	@inlinable var isSymbolicLink: Bool {
		(try? resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) ?? false
	}

	@inlinable var isWritable: Bool {
		(try? resourceValues(forKeys: [.isWritableKey]).isWritable) ?? false
	}

	@inlinable var isReadable: Bool {
		(try? resourceValues(forKeys: [.isReadableKey]).isReadable) ?? false
	}
}

extension FileManager {
	func directorySize(atPath path: URL) throws -> UInt {
		var size: UInt = 0

		let files = try FileManager.default.subpathsOfDirectory(atPath: path.path)
		for file in files {
			guard let attributes = try? FileManager.default.attributesOfItem(atPath: path.appending(path: file).path) else {
				continue
			}

			guard let fileSize = attributes[.size] as? Int64 else {
				continue
			}

			size = size + UInt(fileSize)
		}

		return size
	}
}

extension DefaultStringInterpolation {
	mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T, color: ASCIIColor) {
		appendInterpolation("\(color.rawValue)\(value)\(ASCIIColor.default.rawValue)")
	}
}

extension UInt {
	private static let suffixes: [ByteFormatting: [String]] = [
		.baseTen: ["bytes", "kb", "mb", "gb", "tb", "pb", "eb", "zb", "yb"],
		.powerOfTwo: ["bytes", "kib", "mib", "gib", "tib", "pib", "eib", "zib", "yib"],
	]

	func formatted(byteBase format: ByteFormatting) -> String {
		if self == 0 {
			return "empty"
		}

		let base = Double(format.rawValue)
		let bytes = Double(self)

		let index = floor(log(bytes) / log(base))

		let numberFormatter = NumberFormatter()
		numberFormatter.maximumFractionDigits = 2
		numberFormatter.numberStyle = .decimal

		guard let string = numberFormatter.string(from: NSNumber(value: bytes / pow(base, index))) else {
			return String(self, radix: 10)
		}

		guard let suffix = UInt.suffixes[format]?[Int(index)] else {
			return String(self, radix: 10)
		}

		return "\(string) \(suffix)"
	}
}

extension Date {
	var nowOrNever: String {
		if self.timeIntervalSince1970 == 0 {
			return "never"
		}

		return self.description
	}
}
