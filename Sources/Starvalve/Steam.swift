// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

/// Which platform this is for.
public enum SteamUniverse: Int {
	case invalid
	case steam
	case beta
	case closed
	case dev
	case rc
}

public enum SteamAccountType: Int {
	case invalid
	case profile
	case multiseat
	case gameServer
	case anonymousGameServer
	case pending
	case contentServer
	case group
	case chat
	case peer
	case anonymousUser
}
