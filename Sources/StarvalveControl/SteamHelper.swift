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
	let acfPath: URL
	let workshopAcfPath: URL
	let workshopPath: URL
	let compatDataPath: URL
	let shaderCachePath: URL

	init?(libraryPath library: URL, appId: UInt, detailed: Bool = true) {
		acfPath = library.appending(path: "steamapps/appmanifest_\(appId).acf", directoryHint: .notDirectory)
		workshopAcfPath = library.appending(path: "steamapps/workshop/appworkshop_\(appId).acf", directoryHint: .notDirectory)
		workshopPath = library.appending(path: "steamapps/workshop/content/\(appId)", directoryHint: .isDirectory)
		compatDataPath = library.appending(path: "steamapps/compatdata/\(appId)", directoryHint: .isDirectory)
		shaderCachePath = library.appending(path: "steamapps/shadercache/\(appId)", directoryHint: .isDirectory)

		guard let vdf = try? TextVDF.read(url: acfPath) else {
			return nil
		}

		guard let acf = ApplicationContentFile(vdf: vdf) else {
			return nil
		}

		self.acf = acf

		guard detailed else {
			workshop = nil
			compatDataSize = 0
			shaderCacheSize = 0
			return
		}

		if let vdf = try? TextVDF.read(url: workshopAcfPath),
			let workshopAcf = ApplicationContentFile(vdf: vdf)
		{
			workshop = workshopAcf
		} else {
			workshop = nil
		}

		if compatDataPath.isDirectory {
			self.compatDataSize = (try? FileManager.default.directorySize(atPath: compatDataPath)) ?? 0
		} else {
			self.compatDataSize = 0
		}

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
				preconditionFailure("⚠️ Could not locate Steam installation")
			}

			self.steamPath = steamPath.canonicalPath
		}

		guard self.steamPath.isDirectory else {
			preconditionFailure("⚠️ Path \"\(self.steamPath)\" does not exist")
		}
	}

	var libraryFolders: SteamLibraryFolders? {
		get {
			let path = steamPath.appending(path: "config/libraryfolders.vdf", directoryHint: .notDirectory)
			guard let vdf = try? TextVDF.read(url: path) else {
				return nil
			}

			return SteamLibraryFolders(vdf: vdf)
		}
		set {
			guard let libraries = newValue else {
				return
			}

			let path = steamPath.appending(path: "config/libraryfolders.vdf", directoryHint: .notDirectory)
			let altPath = steamPath.appending(path: "steamapps/libraryfolders.vdf", directoryHint: .notDirectory)
			let vdf = libraries.vdf()
			try? TextVDF.write(url: path, vdf: vdf)
			try? TextVDF.write(url: altPath, vdf: vdf)  // ?????
		}
	}

	var users: [SteamID: String] {
		let path = steamPath.appending(path: "config/loginusers.vdf", directoryHint: .notDirectory)
		guard let vdf = try? TextVDF.read(url: path) else {
			return [:]
		}

		var result: [SteamID: String] = [:]
		for item in vdf {
			guard let id = item.key.unsigned else {
				continue
			}
			guard let name = item["PersonaName"]?.string ?? item["AccountName"]?.string else {
				continue
			}
			result[SteamID(rawValue: id)] = name
		}

		return result
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
