// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Foundation

#if os(Linux)
	import Glibc
#elseif os(Windows)
	import CRT
#else
	import Darwin
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

	static var isTerminalSupported: Bool {
		#if os(Windows)
			let isatty = _isatty
		#endif
		if ProcessInfo.processInfo.environment["STARVALVE_USE_COLOR"] != nil {
			return true
		}

		guard let termType = ProcessInfo.processInfo.environment["TERM"],
			termType.lowercased() != "dumb" && isatty(STDOUT_FILENO) != 0
		else {
			return false
		}
		return true
	}
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

			if let fileType = attributes[.type] as? FileAttributeType,
				fileType == .typeSymbolicLink
			{
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
		if ASCIIColor.isTerminalSupported {
			appendInterpolation("\(color.rawValue)\(value)\(ASCIIColor.default.rawValue)")
		} else {
			appendInterpolation(value)
		}
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

extension TimeInterval {
	var durationDescription: String {
		var value = Int(self)

		if value <= 0 {
			return "zero seconds"
		}

		// DateComponentsFormatter is not implemented outside of Apple platforms
		let secondsInMinute = 60
		let secondsInHour = 3600
		let secondsInDay = 86400
		let secondsInWeek = 604800
		let secondsInMonth = 2_624_016
		let secondsInYear = 31_556_952

		var parts: [String] = []
		if value > secondsInYear {
			let years = value / secondsInYear
			parts.append("\(years) year\(years != 1 ? "s" : "")")
			value -= years * secondsInYear
		}

		if value > secondsInMonth {
			let months = value / secondsInMonth
			parts.append("\(months) month\(months != 1 ? "s" : "")")
			value -= months * secondsInMonth
		}

		if value > secondsInWeek {
			let weeks = value / secondsInWeek
			parts.append("\(weeks) week\(weeks != 1 ? "s" : "")")
			value -= weeks * secondsInWeek
		}

		if value > secondsInDay {
			let days = value / secondsInDay
			parts.append("\(days) day\(days != 1 ? "s" : "")")
			value -= days * secondsInDay
		}

		if value > secondsInHour {
			let hours = value / secondsInHour
			parts.append("\(hours) hour\(hours != 1 ? "s" : "")")
			value -= hours * secondsInHour
		}

		if value > secondsInMinute {
			let minutes = value / secondsInMinute
			parts.append("\(minutes) minute\(minutes != 1 ? "s" : "")")
			value -= minutes * secondsInMinute
		}

		if value > 0 {
			parts.append("\(value) second\(value != 1 ? "s" : "")")
		}

		if parts.count > 1 {
			parts.append("and \(parts.removeLast())")
		}

		return parts.joined(separator: ", ")
	}
}
