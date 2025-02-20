// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import ArgumentParser
import Foundation
import Starvalve

struct BrickDOSDevicesCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "dosdevices",
		abstract: "Stubs all valid DOS devices so Steam's runtime cannot make new ones."
	)

	@Option(name: .customLong("compat"), help: "Path to the related compatdata")
	var compatPath: String? = nil

	@Option(name: .customLong("appId"), help: "Path to the related compatdata")
	var appId: UInt? = nil

	@OptionGroup var volatile: VolatileOptions

	@OptionGroup var globals: GlobalOptions

	func run() {
		if let compatPath = compatPath {
			stubDevices(URL(filePath: compatPath, directoryHint: .isDirectory))
			return
		}

		let steam = SteamHelper(steamPath: globals.steamPath)

		guard let libraries = steam.libraryFolders else {
			print("⚠️ Steam libraries failed to parse.")
			return
		}

		if let appId = appId {
			for library in libraries.entries {
				if library.apps.contains(where: { (key: UInt, value: UInt) in
					key == appId
				}) {
					stubDevices(library.path.appending(path: "compatdata/\(appId)/", directoryHint: .isDirectory).canonicalPath)
					break
				}
			}
		} else {
			for library in libraries.entries {
				for appId in library.apps.keys {
					print("handling app \(appId)")
					stubDevices(library.path.appending(path: "compatdata/\(appId)/", directoryHint: .isDirectory).canonicalPath)
				}
			}
		}
	}

	func stubDevices(_ path: URL) {
		let devicesPath = path.appending(path: "pfx/dosdevices", directoryHint: .isDirectory)
		guard FileManager.default.fileExists(atPath: devicesPath.path) else {
			return
		}

		if volatile.interactive {
			print("Stub DOS Devices for \"\(devicesPath.path, color: .red)\"? [Y/n]:", terminator: " ")
			guard let line = readLine(strippingNewline: true),
				let firstChar = line.lowercased().first,
				firstChar == "y"
			else {
				return
			}
		}

		let a = Int(Character("a").asciiValue!)
		let null = URL(filePath: "/dev/null")

		for index in 0...25 {
			guard let scalar = UnicodeScalar(a + index) else {
				continue
			}

			let letter = Character(scalar)
			if letter == "z" || letter == "c" {
				continue
			}

			let devicePath = devicesPath.appending(path: "\(letter):", directoryHint: .isDirectory)
			let realDevicePath = devicesPath.appending(path: "\(letter)::", directoryHint: .isDirectory)
			guard !devicePath.isSymbolicLink || !FileManager.default.fileExists(atPath: devicePath.path) else {
				continue
			}
			print("linking \(letter): to /dev/null")

			guard !volatile.dry else {
				continue
			}

			try? FileManager.default.removeItem(at: devicePath)
			try? FileManager.default.removeItem(at: realDevicePath)

			try? FileManager.default.createSymbolicLink(at: devicePath, withDestinationURL: null)
			try? FileManager.default.createSymbolicLink(at: realDevicePath, withDestinationURL: null)
		}
	}
}
