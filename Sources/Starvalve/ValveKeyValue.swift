// SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
// SPDX-License-Identifier: EUPL-1.2

/// Node value structure for VDF elements.
public struct ValveKeyValueNode: VDFInitializable, ExpressibleByStringLiteral {
	public let value: String?

	public var description: String {
		guard let value = value else {
			return "nil"
		}
		return value
	}

	public init() {
		self.value = nil
	}

	public init(_ string: String) {
		self.value = string
	}

	public init(stringLiteral value: String) {
		self.value = value
	}

	public init(signed: Int) {
		self.value = String(signed)
	}

	public init(unsigned: UInt) {
		self.value = String(unsigned)
	}

	public init(float: Float) {
		self.value = String(describing: float)
	}

	public init(double: Double) {
		self.value = String(describing: double)
	}

	public init(bool: Bool) {
		self.value = bool ? "1" : "0"
	}

	public init(vdfValue: ValveKeyValueNode) {
		self = vdfValue
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

	public func vdf() -> ValveKeyValueNode {
		return self
	}
}

/// An element for VDF structures.
public class ValveKeyValue: Sequence, VDFContent {
	public typealias Element = ValveKeyValue
	public typealias Iterator = [ValveKeyValue].Iterator

	public var key: ValveKeyValueNode
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

	public init(_ key: ValveKeyValueNode) {
		self.key = key
		self.value = ValveKeyValueNode()
	}

	public init(key: ValveKeyValueNode, value: ValveKeyValueNode) {
		self.key = key
		self.value = value
	}

	public init(key: ValveKeyValueNode, children: [ValveKeyValue]) {
		self.key = key
		self.value = ValveKeyValueNode()
		self.children = children
	}

	public required init(vdf: ValveKeyValue) {
		self.key = vdf.key
		self.value = vdf.value
		self.children = [ValveKeyValue](vdf.children)
	}

	public init(key: ValveKeyValueNode, vdf: VDFInitializable) {
		self.key = key
		self.value = vdf.vdf()
		self.children = []
	}

	public init(key: ValveKeyValueNode, vdf: VDFContent) {
		self.key = key
		let nested = vdf.vdf()
		self.value = nested.value
		self.children = [ValveKeyValue](nested.children)
	}

	public init(key: VDFInitializable, vdf: VDFInitializable) {
		self.key = key.vdf()
		self.value = vdf.vdf()
		self.children = []
	}

	public init(key: VDFInitializable, vdf: VDFContent) {
		self.key = key.vdf()
		let nested = vdf.vdf()
		self.value = nested.value
		self.children = [ValveKeyValue](nested.children)
	}

	public init(key: ValveKeyValueNode, vdf: ValveKeyValue) {
		self.key = key
		self.value = vdf.value
		self.children = [ValveKeyValue](vdf.children)
	}

	public init<T: VDFContent>(key: ValveKeyValueNode, sequence: [T]) {
		self.key = key
		self.value = ValveKeyValueNode()
		var index = 0
		self.children = sequence.compactMap { vdf in
			let result = ValveKeyValue(key: ValveKeyValueNode(signed: index), vdf: vdf)
			index += 1
			return result
		}
	}

	public init<T: VDFInitializable>(key: ValveKeyValueNode, sequence: [T]) {
		self.key = key
		self.value = ValveKeyValueNode()
		var index = 0
		self.children = sequence.compactMap { vdf in
			let result = ValveKeyValue(key: ValveKeyValueNode(signed: index), vdf: vdf)
			index += 1
			return result
		}
	}

	public init<TKey: VDFInitializable, TValue: VDFContent>(key: ValveKeyValueNode, map: [TKey: TValue]) {
		self.key = key
		self.value = ValveKeyValueNode()
		self.children = map.compactMap { (key, value) in
			ValveKeyValue(key: key, vdf: value)
		}
	}

	public init<TKey: VDFInitializable, TValue: VDFInitializable>(key: ValveKeyValueNode, map: [TKey: TValue]) {
		self.key = key
		self.value = ValveKeyValueNode()
		self.children = map.compactMap { (key, value) in
			ValveKeyValue(key: key, vdf: value)
		}
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

	public func vdf() -> ValveKeyValue {
		return self
	}

	public func firstIndex(key name: String) -> Int? {
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

	public func lastIndex(key name: String) -> Int? {
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

	public func to<T: VDFContent>(as type: T.Type) -> T? {
		return type.init(vdf: self)
	}

	public func to<T: VDFInitializable>(as type: T.Type) -> T? {
		return type.init(vdfValue: value)
	}

	public func to<T: VDFContent>(sequence type: T.Type) -> [T] {
		return makeIterator().compactMap { kv in
			type.init(vdf: kv)
		}
	}

	public func to<T: VDFInitializable>(sequence type: T.Type) -> [T] {
		return makeIterator().compactMap { kv in
			type.init(vdfValue: kv.value)
		}
	}

	public func to<TKey: VDFInitializable, TValue: VDFContent>(key keyType: TKey.Type, value valueType: TValue.Type) -> [TKey: TValue] {
		var result: [TKey: TValue] = [:]

		for element in makeIterator() {
			guard let key = TKey.init(vdfValue: element.key) else {
				continue
			}

			guard let value = TValue.init(vdf: element) else {
				continue
			}

			result[key] = value
		}

		return result
	}

	public func to<TKey: VDFInitializable, TValue: VDFInitializable>(key keyType: TKey.Type, value valueType: TValue.Type) -> [TKey: TValue] {
		var result: [TKey: TValue] = [:]

		for element in makeIterator() {
			guard let key = TKey.init(vdfValue: element.key) else {
				continue
			}

			guard let value = TValue.init(vdfValue: element.value) else {
				continue
			}

			result[key] = value
		}

		return result
	}

	public subscript(index: Int) -> ValveKeyValue? {
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

	public subscript(name: String) -> ValveKeyValue? {
		guard let index = firstIndex(key: name) else {
			return nil
		}

		return children[index]
	}

	public subscript(key: ValveKeyValueNode) -> ValveKeyValueNode? {
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
