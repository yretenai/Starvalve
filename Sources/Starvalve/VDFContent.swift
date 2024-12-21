// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

/// Protocol for types that can serialize to and from ValveKeyValue.
public protocol VDFContent {
	init?(vdf: ValveKeyValue)

	func vdf() -> ValveKeyValue
}

/// Protocol for types that can serialize to and from ValveKeyValueNode.
public protocol VDFInitializable {
	/// initialize this type via a VDF node
	init?(vdfValue: ValveKeyValueNode)

	/// convert this type to a VDF node
	func vdf() -> ValveKeyValueNode
}

extension String: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let str = vdfValue.string else {
			return nil
		}
		self = str
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(self)
	}
}

extension Bool: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let bool = vdfValue.bool else {
			return nil
		}
		self = bool
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(bool: self)
	}
}

extension Int: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let signed = vdfValue.signed else {
			return nil
		}
		self = signed
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(signed: self)
	}
}

extension UInt: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let unsigned = vdfValue.unsigned else {
			return nil
		}
		self = unsigned
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(unsigned: self)
	}
}

extension Int8: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let signed = vdfValue.signed else {
			return nil
		}
		self = Int8(signed)
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(signed: Int(self))
	}
}

extension UInt8: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let unsigned = vdfValue.unsigned else {
			return nil
		}
		self = UInt8(unsigned)
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(unsigned: UInt(self))
	}
}

extension Int16: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let signed = vdfValue.signed else {
			return nil
		}
		self = Int16(signed)
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(signed: Int(self))
	}
}

extension UInt16: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let unsigned = vdfValue.unsigned else {
			return nil
		}
		self = UInt16(unsigned)
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(unsigned: UInt(self))
	}
}

extension Int32: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let signed = vdfValue.signed else {
			return nil
		}
		self = Int32(signed)
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(signed: Int(self))
	}
}

extension UInt32: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let unsigned = vdfValue.unsigned else {
			return nil
		}
		self = UInt32(unsigned)
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(unsigned: UInt(self))
	}
}

extension Int64: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let signed = vdfValue.signed else {
			return nil
		}
		self = Int64(signed)
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(signed: Int(self))
	}
}

extension UInt64: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let unsigned = vdfValue.unsigned else {
			return nil
		}
		self = UInt64(unsigned)
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(unsigned: UInt(self))
	}
}

extension Int128: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let signed = vdfValue.signed else {
			return nil
		}
		self = Int128(signed)
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(String(self))
	}
}

extension UInt128: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let unsigned = vdfValue.unsigned else {
			return nil
		}
		self = UInt128(unsigned)
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(String(self))
	}
}

extension Double: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let double = vdfValue.double else {
			return nil
		}
		self = double
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(double: self)
	}
}

extension Float: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let float = vdfValue.float else {
			return nil
		}
		self = float
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(float: self)
	}
}

extension Float16: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let float = vdfValue.float else {
			return nil
		}
		self = Float16(float)
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(float: Float(self))
	}
}

extension Float80: VDFInitializable {
	/// initialize this type via a VDF key value element.
	public init?(vdfValue: ValveKeyValueNode) {
		guard let double = vdfValue.double else {
			return nil
		}
		self = Float80(double)
	}

	/// convert this type to a VDF key value element.
	public func vdf() -> ValveKeyValueNode {
		return ValveKeyValueNode(double: Double(self))
	}
}
