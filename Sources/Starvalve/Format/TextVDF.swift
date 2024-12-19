// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

enum TextVDFToken {
	case string(value: String)
	case openDict
	case closeDict
}

extension CharacterSet {
	func contains(character: Character) -> Bool {
		return character.unicodeScalars.allSatisfy(contains(_:))
	}
}

class TextVDFLexer {
	private let content: String
	private var index: String.Index

	// need order so can't use a map
	static let unescapeSequences: [(String, String)] = [
		(#"\n"#, "\n"),
		(#"\t"#, "\t"),
		(#"\r"#, "\r"),
		(#"\?"#, "?"),
		(#"\""#, "\""),
		(#"\'"#, "'"),
		(#"\\"#, #"\"#),
	]

	init(_ content: String) {
		self.content = content
		index = self.content.startIndex
	}

	func next() throws -> TextVDFToken? {
		while index < content.endIndex {
			advance(CharacterSet.whitespacesAndNewlines)
			let char = content[index]
			if char == "\"" {
				advance()
				var string = ""
				let charCount = content.distance(from: index, to: content.endIndex)
				var currentIndex = 0
				while currentIndex < charCount {
					let subChar = content[content.index(index, offsetBy: currentIndex)]
					currentIndex = currentIndex + 1

					if subChar == "\"" {
						advance(by: currentIndex)
						for (replaceLeft, replaceRight) in TextVDFLexer.unescapeSequences {
							string.replace(replaceLeft, with: replaceRight)
						}
						return .string(value: string)
					}

					string.append(subChar)

					if subChar == "\\" {
						guard currentIndex < charCount else {
							throw TextVDFError.unterminatedString
						}

						string.append(content[content.index(index, offsetBy: currentIndex)])
						currentIndex = currentIndex + 1
					}

				}
				throw TextVDFError.unterminatedString
			} else if char == "{" {
				advance()
				return .openDict
			} else if char == "}" {
				advance()
				return .closeDict
			} else {
				throw TextVDFError.unexpectedToken
			}
		}

		return nil
	}

	func advance(_ characters: CharacterSet) {
		let skip = content[index...].prefix { char in
			characters.contains(character: char)
		}.count

		advance(by: skip)
	}

	func advance(by: Int = 1) {
		guard by > 0 else {
			return
		}

		let newIndex = content.index(index, offsetBy: by)

		guard newIndex < content.endIndex else {
			self.index = content.endIndex
			return
		}

		self.index = newIndex
	}
}

/// reader and writer for text-based VDF files.
public struct TextVDF {
	@available(*, unavailable) private init() {}

	public static func read(string: any StringProtocol) throws -> ValveKeyValue? {
		var memo: [ValveKeyValue] = []
		var current: ValveKeyValue?
		var key: ValveKeyValueNode?
		let lexer = TextVDFLexer(String(string))

		while let token = try lexer.next() {
			switch token {
			case .closeDict:
				guard let last = memo.popLast() else {
					return current
				}

				current = last
			case .openDict:
				guard let currentKey = key else {
					throw TextVDFError.missingKey
				}

				let next = ValveKeyValue(currentKey)
				if let current: ValveKeyValue = current {
					current.append(next)
					memo.append(current)
				}

				current = next
				key = nil
			case .string(let value):
				if let currentKey: ValveKeyValueNode = key {
					guard let current = current else {
						throw TextVDFError.insertingIntoRootValue
					}

					current[currentKey] = ValveKeyValueNode(value)
					key = nil
				} else {
					key = ValveKeyValueNode(value)
				}
			}
		}

		throw TextVDFError.truncated
	}

	public static func write(vdf: ValveKeyValue) throws -> String {
		return try write(vdf: vdf, indent: 0)
	}

	static func write(vdf: ValveKeyValue, indent indentLevel: Int) throws -> String {
		guard var key = vdf.key.string else {
			throw TextVDFError.missingKey
		}

		guard !vdf.children.isEmpty || !vdf.value.isNil else {
			throw TextVDFError.missingValue
		}

		for (replaceRight, replaceLeft) in TextVDFLexer.unescapeSequences.reversed() {
			key.replace(replaceLeft, with: replaceRight)
		}

		let indent = String(repeating: "\t", count: indentLevel)
		var result = "\(indent)\"\(key)\""
		if !vdf.children.isEmpty {
			result.append("\n\(indent){\n")
			for child in vdf {
				result.append(try TextVDF.write(vdf: child, indent: indentLevel + 1))
			}
			result.append("\(indent)}\n")
		} else {
			guard var value = vdf.value.string else {
				throw TextVDFError.missingValue
			}

			for (replaceRight, replaceLeft) in TextVDFLexer.unescapeSequences.reversed() {
				value.replace(replaceLeft, with: replaceRight)
			}

			result.append("\t\t\"\(value)\"\n")
		}

		return result
	}
}
