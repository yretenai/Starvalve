// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation

#if canImport(WinSDK)
	import WinSDK
#endif

struct SteamHelper {
	let steamPath: String

	init(steamPath: String?) {
		guard let steamPath = steamPath ?? SteamHelper.findSteam() else {
			preconditionFailure("Could not locate Steam installation")
		}

		self.steamPath = steamPath

		var isDirectory: Bool = false
		guard FileManager.default.fileExists(atPath: self.steamPath, isDirectory: &isDirectory) && isDirectory else {
			preconditionFailure("Path \"\(self.steamPath)\" does not exist")
		}
	}

	static func findSteam() -> String? {
		#if os(Linux)
			let home = FileManager.default.homeDirectoryForCurrentUser
			return home.appending(path: ".steam/root", directoryHint: .isDirectory).path()
		#elseif os(macOS)
			let home = FileManager.default.homeDirectoryForCurrentUser
			return home.appending(path: "Library/Application Support/Steam", directoryHint: .isDirectory).path()
		#elseif os(Windows)
			#if canImport(WinSDK)
				if let path = SteamHelper.findSteamViaRegistry() {
					return path
				}
			#endif
			let programFilesPath = URL(filePath: ProcessInfo.processInfo.environment["ProgramFiles(x86)"] ?? #"C:\Program Files (x86)"#, directoryHint: .isDirectory)
			return programFilesPath.appending(path: "Steam", directoryHint: .isDirectory).path()
		#else
			return nil
		#endif
	}

	#if canImport(WinSDK)
		static func findSteamViaRegistry() -> String? {
			return #"SOFTWARE\Valve\Steam"#.withCString(encodedAs: UTF16.self) { regPath in
				return "InstallPath".withCString(encodedAs: UTF16.self) { regKey in
					var size: DWORD = PATH_MAX
					var buffer: [WCHAR] = [WCHAR](repeating: 0, count: size)
					guard RegGetValueW(HKEY_LOCAL_MACHINE, regPath, regKey, RRF_RT_REG_SZ | RRF_SUBKEY_WOW6432KEY | RRF_ZEROONFAILURE, nil, &buffer, &size) == ERROR_SUCCESS else {
						return nil
					}
					return String(decodingCString: buffer, as: UTF16.self)
				}
			}
		}
	#endif
}
