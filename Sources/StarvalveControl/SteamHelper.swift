// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import Foundation
import Starvalve

#if canImport(WinSDK)
	import WinSDK
#endif

struct AppInfo {
	let acf: ApplicationContentFile
	let workshop: ApplicationContentFile?
	let compatDataSize: UInt
	let shaderCacheSize: UInt

	init?(libraryPath library: URL, appId: UInt) {
		let path = library.appending(path: "steamapps/appmanifest_\(appId).acf", directoryHint: .notDirectory)
		guard let vdf = try? TextVDF.read(url: path) else {
			return nil
		}

		guard let acf = ApplicationContentFile(vdf: vdf) else {
			return nil
		}

		self.acf = acf

		let workshopPath = library.appending(path: "steamapps/workshop/appworkshop_\(appId).acf", directoryHint: .notDirectory)
		if let vdf = try? TextVDF.read(url: workshopPath),
			let workshopAcf = ApplicationContentFile(vdf: vdf)
		{
			workshop = workshopAcf
		} else {
			workshop = nil
		}

		let compatDataPath = library.appending(path: "steamapps/compatdata/\(appId)", directoryHint: .isDirectory)
		if compatDataPath.isDirectory {
			self.compatDataSize = (try? FileManager.default.directorySize(atPath: compatDataPath)) ?? 0
		} else {
			self.compatDataSize = 0
		}

		let shaderCachePath = library.appending(path: "steamapps/shadercache/\(appId)", directoryHint: .isDirectory)
		if shaderCachePath.isDirectory {
			self.shaderCacheSize = (try? FileManager.default.directorySize(atPath: shaderCachePath)) ?? 0
		} else {
			self.shaderCacheSize = 0
		}
	}
}

struct SteamHelper {
	let steamPath: URL

	init(steamPath: String?) {
		if let steamPath = steamPath {
			self.steamPath = URL(filePath: steamPath, directoryHint: .isDirectory).canonicalPath
		} else {
			guard let steamPath = SteamHelper.findSteam() else {
				preconditionFailure("Could not locate Steam installation")
			}
			self.steamPath = steamPath.canonicalPath
		}

		guard self.steamPath.isDirectory else {
			preconditionFailure("Path \"\(self.steamPath)\" does not exist")
		}
	}

	var libraryFolders: SteamLibraryFolders? {
		let path = steamPath.appending(path: "config/libraryfolders.vdf", directoryHint: .notDirectory)
		guard let vdf = try? TextVDF.read(url: path) else {
			return nil
		}

		return SteamLibraryFolders(vdf: vdf)
	}

	var appInfo: SteamAppInfo? {
		let path = steamPath.appending(path: "appcache/appinfo.vdf", directoryHint: .notDirectory)
		guard let data = try? Data(contentsOf: path) else {
			return nil
		}

		return try? SteamAppInfo(data: data)
	}

	var packageInfo: SteamPackageInfo? {
		let path = steamPath.appending(path: "appcache/packageinfo.vdf", directoryHint: .notDirectory)
		guard let data = try? Data(contentsOf: path) else {
			return nil
		}

		return try? SteamPackageInfo(data: data)
	}

	static func findSteam() -> URL? {
		#if os(Linux)
			let home = FileManager.default.homeDirectoryForCurrentUser
			return home.appending(path: ".steam/root", directoryHint: .isDirectory)
		#elseif os(macOS)
			guard let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
				return nil
			}
			return applicationSupport.appending(path: "Steam", directoryHint: .isDirectory)
		#elseif os(Windows)
			#if canImport(WinSDK)
				if let path = SteamHelper.findSteamViaRegistry() {
					return path
				}
			#endif
			let programFilesPath = URL(filePath: ProcessInfo.processInfo.environment["ProgramFiles(x86)"] ?? #"C:\Program Files (x86)"#, directoryHint: .isDirectory)
			return programFilesPath.appending(path: "Steam", directoryHint: .isDirectory)
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
					return URL(filePath: String(decodingCString: buffer, as: UTF16.self), directoryHint: .isDirectory)
				}
			}
		}
	#endif
}
