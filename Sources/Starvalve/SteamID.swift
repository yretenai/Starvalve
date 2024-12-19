// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

/// Structure for 64-bit SteamIDs.
public struct SteamID {
	public var rawValue: UInt

	public var description: String {
		type == .pending ? "STEAM_ID_PENDING" : "STEAM_\(universe.rawValue):\(live ? 1 : 0):\(clientID)"
	}

	public var steam3: String {
		let letter =
			switch type {
				case .invalid: "I"
				case .profile: "U"
				case .multiseat: "M"
				case .gameServer: "G"
				case .anonymousGameServer: "A"
				case .pending: "P"
				case .contentServer: "C"
				case .group: "g"
				case .chat: "c"
				case .peer: "p"
				case .anonymousUser: "a"
			}

		return "[\(letter):\(universe.rawValue):\(accountID)]"
	}

	public var hex: String {
		"steam:\(String(format:"%x", rawValue))"
	}

	public var live: Bool {
		get {
			(rawValue & 1) == 1
		}
		set {
			rawValue = (rawValue & ~1) | (newValue ? 1 : 0)
		}
	}

	public var clientID: Int {
		get {
			Int((rawValue >> 1) & 0x7FFF_FFFF)
		}
		set {
			rawValue = (rawValue & ~(0x7FFF_FFFF << 1)) | (UInt(newValue & 0x7FFF_FFFF) << 1)
		}
	}

	public var accountID: UInt {
		get {
			UInt(rawValue & 0xFFFF_FFFF)
		}
		set {
			rawValue = (rawValue & ~0xFFFF_FFFF) | UInt(newValue & 0xFFFF_FFFF)
		}
	}

	public var instanceID: UInt {
		get {
			UInt((rawValue >> 32) & 0xFFFFF)
		}
		set {
			rawValue = (rawValue & ~(0xFFFFF << 32)) | (UInt(newValue & 0xFFFFF) << 32)
		}
	}

	public var type: SteamAccountType {
		get {
			SteamAccountType(rawValue: Int((rawValue >> 52) & 0xF)) ?? .invalid
		}
		set {
			rawValue = (rawValue & ~(0xF << 52)) | (UInt(newValue.rawValue & 0xF) << 52)
		}
	}

	public var universe: SteamUniverse {
		get {
			SteamUniverse(rawValue: Int((rawValue >> 56) & 0xFF)) ?? .invalid
		}
		set {
			rawValue = (rawValue & ~(0xFF << 56)) | (UInt(newValue.rawValue & 0xFF) << 56)
		}
	}

	public init() {
		rawValue = 0
	}

	public init(_ value: UInt) {
		rawValue = value
	}

	public init(accountID: UInt, instanceID: UInt = 1, type: SteamAccountType = .profile, universe: SteamUniverse = .steam) {
		self.rawValue = 0
		self.accountID = accountID
		self.instanceID = instanceID
		self.type = type
		self.universe = universe
	}

	public init(clientID: Int, live: Bool, instanceID: UInt = 1, type: SteamAccountType = .profile, universe: SteamUniverse = .steam) {
		self.rawValue = 0
		self.live = live
		self.clientID = clientID
		self.instanceID = instanceID
		self.type = type
		self.universe = universe
	}
}
