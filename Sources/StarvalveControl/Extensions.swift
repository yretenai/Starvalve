// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

#if os(macOS)
	@usableFromInline typealias FileBool = ObjCBool
#else
	@usableFromInline typealias FileBool = Bool
#endif

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

extension FileManager {
	@inlinable func dirExists(atPath url: URL) -> Bool {
		guard url.isFileURL else {
			return false
		}

		var isDirectory: FileBool = false
		guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
			return false
		}

		#if os(macOS)
			return isDirectory.boolValue
		#else
			return isDirectory
		#endif
	}

	@inlinable func fileExists(atPath url: URL) -> Bool {
		guard url.isFileURL else {
			return false
		}

		return FileManager.default.fileExists(atPath: url.path)
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
