// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
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

extension Collection {
	subscript(optionally index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
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

extension URL: @retroactive ExpressibleByArgument {
	/// initializes a string via a string argument.
	public init(argument: String) {
		if let url = URL(string: argument) {
			self = url
		} else {
			self = URL(filePath: argument)
		}
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

extension Date {
	var nowOrNever: String {
		if self.timeIntervalSince1970 == 0 {
			return "never"
		}

		return self.description
	}
}
