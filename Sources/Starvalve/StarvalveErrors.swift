// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

enum DataCursorError: Error {
	case outOfBounds
	case nonNullTerminatedString
}

public enum SteamAppInfoError: Error {
	case unsupported
	case invalidVdf
}

public enum TextVDFError: Error {
	case unexpectedToken
	case unterminatedString
	case truncated
	case insertingIntoRootValue
	case missingKey
	case missingValue
}

public enum BinaryVDFError: Error {
	case stringIndexOutOfRange
	case invalidToken
	case notSupported
}
