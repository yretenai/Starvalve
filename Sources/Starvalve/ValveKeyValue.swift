// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

/// Node value structure for VDF elements.
public struct ValveKeyValueNode {
	public let value: (any StringProtocol)?

	init() {
		self.value = nil
	}

	init(_ string: any StringProtocol) {
		self.value = string
	}

	init(signed: Int) {
		self.value = String(signed)
	}

	init(unsigned: UInt) {
		self.value = String(unsigned)
	}

	init(float: Float) {
		self.value = String(describing: float)
	}

	init(double: Double) {
		self.value = String(describing: double)
	}

	init(bool: Bool) {
		self.value = bool ? "1" : "0"
	}

	public var isNil: Bool {
		return value == nil
	}

	public var string: String? {
		guard !isNil else {
			return nil
		}

		guard let str = value else {
			return nil
		}

		return String(str)
	}

	public var signed: Int? {
		guard !isNil else {
			return nil
		}

		guard let str = value else {
			return nil
		}

		return Int.init(str, radix: 10)
	}

	public var unsigned: UInt? {
		guard !isNil else {
			return nil
		}

		guard let str = value else {
			return nil
		}

		return UInt.init(str, radix: 10)
	}

	public var float: Float? {
		guard !isNil else {
			return nil
		}

		guard let str = value else {
			return nil
		}

		return Float.init(str)
	}

	public var double: Double? {
		guard !isNil else {
			return nil
		}

		guard let str = value else {
			return nil
		}

		return Double.init(str)
	}

	public var bool: Bool? {
		guard let value = signed else {
			return nil
		}

		return value == 1
	}
}

/// An element for VDF structures.
public class ValveKeyValue: Sequence {
	public typealias Element = ValveKeyValue
	public typealias Iterator = Array<ValveKeyValue>.Iterator

	public let key: ValveKeyValueNode
	public var value: ValveKeyValueNode
	public var children: [ValveKeyValue] = []

	public var description: String {
		if children.isEmpty {
			return "ValveKeyValue \"\(key)\" with \(children.count) child nodes"
		} else if let value = value.string {
			return "ValveKeyValue \"\(key)\" = \"\(value)\""
		} else {
			return "ValveKeyValue \"\(key)\""
		}
	}

	init(_ key: ValveKeyValueNode) {
		self.key = key
		self.value = ValveKeyValueNode()
	}

	init(key: ValveKeyValueNode, value: ValveKeyValueNode) {
		self.key = key
		self.value = value
	}

	init(key: ValveKeyValueNode, children: [ValveKeyValue]) {
		self.key = key
		self.value = ValveKeyValueNode()
		self.children = children
	}

	public var isNil: Bool {
		return value.isNil && children.count == 0
	}

	public var string: String? {
		get {
			return value.string
		}
		set {
			guard let target = newValue else {
				value = ValveKeyValueNode()
				return
			}
			value = ValveKeyValueNode(target)
		}
	}

	public var signed: Int? {
		get {
			return value.signed
		}
		set {
			guard let target = newValue else {
				value = ValveKeyValueNode()
				return
			}
			value = ValveKeyValueNode(signed: target)
		}
	}

	public var unsigned: UInt? {
		get {
			return value.unsigned
		}
		set {
			guard let target = newValue else {
				value = ValveKeyValueNode()
				return
			}
			value = ValveKeyValueNode(unsigned: target)
		}
	}

	public var float: Float? {
		get {
			return value.float
		}
		set {
			guard let target = newValue else {
				value = ValveKeyValueNode()
				return
			}
			value = ValveKeyValueNode(float: target)
		}
	}

	public var double: Double? {
		get {
			return value.double
		}
		set {
			guard let target = newValue else {
				value = ValveKeyValueNode()
				return
			}
			value = ValveKeyValueNode(double: target)
		}
	}

	public var bool: Bool? {
		get {
			return value.bool
		}
		set {
			guard let target = newValue else {
				value = ValveKeyValueNode()
				return
			}
			value = ValveKeyValueNode(bool: target)
		}
	}

	public func firstIndex(key name: (any StringProtocol)) -> Int? {
		let lowercased = name.lowercased()
		return children.firstIndex { kv in
			guard let key = kv.key.string else {
				return false
			}
			return key.lowercased().elementsEqual(lowercased)
		}
	}

	public func firstIndex(key name: ValveKeyValueNode) -> Int? {
		guard let key = name.string else {
			return nil
		}

		return firstIndex(key: key)
	}

	public func lastIndex(key name: any StringProtocol) -> Int? {
		let lowercased = name.lowercased()
		return children.lastIndex { kv in
			guard let key = kv.key.string else {
				return false
			}
			return key.lowercased().elementsEqual(lowercased)
		}
	}

	public func lastIndex(key name: ValveKeyValueNode) -> Int? {
		guard let key = name.string else {
			return nil
		}

		return lastIndex(key: key)
	}

	public func remove(at index: Int) {
		guard index >= 0 && index < children.count else {
			return
		}

		children.remove(at: index)
	}

	public func remove(name: String) {
		guard let index = firstIndex(key: name) else {
			return
		}

		children.remove(at: index)
	}

	public func remove(key name: ValveKeyValueNode) {
		guard let key = name.string else {
			return
		}

		remove(name: key)
	}

	public func append(_ newNode: ValveKeyValue) {
		guard let index = firstIndex(key: key) else {
			children.append(newNode)
			return
		}

		children[index] = newNode
	}

	public func makeIterator() -> Iterator {
		return children.makeIterator()
	}

	subscript(index: Int) -> ValveKeyValue? {
		get {
			guard index >= 0 && index < children.count else {
				return nil
			}

			return children[index]
		}
		set {
			guard index >= 0 && index < children.count else {
				return
			}

			guard let newValue = newValue else {
				remove(at: index)
				return
			}

			children[index] = newValue
		}
	}

	subscript(name: String) -> ValveKeyValue? {
		guard let index = firstIndex(key: name) else {
			return nil
		}

		return children[index]
	}

	subscript(key: ValveKeyValueNode) -> ValveKeyValueNode? {
		get {
			guard let index = firstIndex(key: key) else {
				return nil
			}

			return children[index].value
		}
		set {
			guard let newValue = newValue else {
				remove(key: key)
				return
			}

			let newNode = ValveKeyValue(key: key, value: newValue)
			append(newNode)
		}
	}
}
