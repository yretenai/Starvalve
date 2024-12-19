// Targets are the basic building blocks of a package, defining a module or a test suite.
// Targets can depend on other targets in this package and products from dependencies.

import Foundation
import Testing

@testable import Starvalve

let basicSample = #"""
	"Test"
	{
		"key"		"value"
		"escapedKey"		"Hello\nWorld!"
		"children1"
		{
			"1"		"value"
			"2"		"value"
		}
		"children2"
		{
			"key"		"value"
			"anotherKey"		"value"
		}
	}
	"""#

let conversionSample = #"""
	"StarvalveTest"
	{
		"signed"		"-9223372036854775808"
		"unsigned"		"18446744073709551615"
		"float"		"1.0"
		"double"		"2.0"
		"string"		"Neptune is the eighth and most distant planet from our central star, light blue gas giant with supersonic winds and a faint ring system."
		"escaped"		"\"\n\t\\"
		"children"
		{
			"1"		"2"
		}
	}
	"""#

let acfSample = """
	"AppState"
	{
		"appid"		"220"
		"universe"		"1"
		"name"		"Half-Life 2"
		"StateFlags"		"4"
		"installdir"		"Half-Life 2"
		"LastUpdated"		"1734561898"
		"LastPlayed"		"0"
		"SizeOnDisk"		"5772874506"
		"StagingSize"		"0"
		"buildid"		"16557524"
		"LastOwner"		"76561198027374592"
		"UpdateResult"		"0"
		"BytesToDownload"		"6116747936"
		"BytesDownloaded"		"6116747936"
		"BytesToStage"		"11129685301"
		"BytesStaged"		"11129685301"
		"TargetBuildID"		"16557524"
		"AutoUpdateBehavior"		"0"
		"AllowOtherDownloadsWhileRunning"		"0"
		"ScheduledAutoUpdate"		"0"
		"StagingFolder"		"0"
		"InstalledDepots"
		{
			"233"
			{
				"manifest"		"5341507048774783651"
				"size"		"3219809668"
			}
			"234"
			{
				"manifest"		"488462887721122399"
				"size"		"3175"
			}
			"221"
			{
				"manifest"		"44432101604462279"
				"size"		"5435904733"
			}
			"224"
			{
				"manifest"		"4249846673673068496"
				"size"		"336987213"
			}
		}
		"SharedDepots"
		{
			"389"		"380"
			"380"		"380"
			"420"		"420"
			"340"		"340"
		}
		"UserConfig"
		{
			"language"		"english"
		}
		"MountedConfig"
		{
			"language"		"english"
		}
	}
	"""

@Test func basicTest() throws {
	let vdf = try #require(try TextVDF.read(string: basicSample))

	#expect(vdf.key.string == "Test")
	#expect(vdf.children.count == 4)

	let child1 = vdf.children[0]
	let child2 = vdf.children[1]
	let child3 = vdf.children[2]
	let child4 = vdf.children[3]

	#expect(child1.key.string == "key")
	#expect(child2.key.string == "escapedKey")
	#expect(child3.key.string == "children1")
	#expect(child4.key.string == "children2")

	#expect(child1.value.string == "value")
	#expect(child2.value.string == "Hello\nWorld!")
	#expect(child3.value.isNil)
	#expect(child4.value.isNil)
}

@Test func inverseBasicTest() throws {
	let vdf = try #require(try TextVDF.read(string: basicSample))
	let text = try #require(try TextVDF.write(vdf: vdf)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

	#expect(text == basicSample)
}

@Test func conversionTest() throws {
	let vdf = try #require(try TextVDF.read(string: conversionSample))

	#expect(vdf.key.string == "StarvalveTest")
	#expect(vdf.children.count == 7)

	#expect(vdf.children[0].signed == -9_223_372_036_854_775_808)
	#expect(vdf.children[1].unsigned == 18_446_744_073_709_551_615)
	#expect(vdf.children[2].float == 1.0)
	#expect(vdf.children[3].double == 2.0)
	#expect(vdf.children[4].string == "Neptune is the eighth and most distant planet from our central star, light blue gas giant with supersonic winds and a faint ring system.")
	#expect(vdf.children[5].string == "\"\n\t\\")
	#expect(vdf.children[6].children.count == 1)
}

@Test func inverseConversionTest() throws {
	let vdf = try #require(try TextVDF.read(string: conversionSample))
	let text = try #require(try TextVDF.write(vdf: vdf)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

	#expect(text == conversionSample)
}

@Test func acfTest() throws {
	let vdf = try #require(try TextVDF.read(string: acfSample))
	let acf = try #require(ApplicationContentFile.init(vdf))

	#expect(acf.appId == 220)
	#expect(acf.universe == .steam)
	#expect(acf.name == "Half-Life 2")
	#expect(acf.stateFlags.contains(.fullyInstalled))
	#expect(acf.installDir == "Half-Life 2")
	#expect(acf.lastUpdated == Date(timeIntervalSince1970: TimeInterval(1_734_561_898)))
	#expect(acf.lastPlayed == Date(timeIntervalSince1970: TimeInterval(0)))
	#expect(acf.sizeOnDisk == 5_772_874_506)
	#expect(acf.stagingSize == 0)
	#expect(acf.buildID == 16_557_524)
	#expect(acf.lastOwner == 76_561_198_027_374_592)
	#expect(acf.updateResult == .success)
	#expect(acf.bytesToDownload == 6_116_747_936)
	#expect(acf.bytesDownloaded == 6_116_747_936)
	#expect(acf.bytesToStage == 11_129_685_301)
	#expect(acf.bytesStaged == 11_129_685_301)
	#expect(acf.targetBuildID == 16_557_524)
	#expect(acf.autoUpdateBehavior == .automatic)
	#expect(acf.allowOtherDownloadsWhileRunning == .deferToGlobalSetting)
	#expect(acf.scheduledAutoUpdate == Date(timeIntervalSince1970: TimeInterval(0)))
	#expect(acf.stagingFolder == 0)
	// todo: check sub values
}

@Test func inverseAcfTest() throws {
	let vdf = try #require(try TextVDF.read(string: acfSample))
	let text = try #require(try TextVDF.write(vdf: vdf)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

	#expect(text == acfSample)
}
