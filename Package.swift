// swift-tools-version: 6.0
// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

import PackageDescription

let package = Package(
	name: "Starvalve",
	platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18), .watchOS(.v11), .macCatalyst(.v18)],
	products: [
		.library(
			name: "Starvalve",
			targets: ["Starvalve"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
	],
	targets: [
		.target(
			name: "Starvalve"),
		.executableTarget(
			name: "starvalvectl",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"Starvalve",
			],
			path: "Sources/StarvalveControl"
		),
		.testTarget(
			name: "StarvalveTests",
			dependencies: ["Starvalve"]
		),
	]
)
