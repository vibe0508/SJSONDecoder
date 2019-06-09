//
//  UnkeyedContainer.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

struct UnkeyedContainer: CodingPathHolder {
    let codingPath: [CodingKey]
    let values: [Value]

    private(set) var currentIndex: Int = 0

    init(codingPath: [CodingKey], values: [Value]) {
        self.codingPath = codingPath
        self.values = values
    }

    private var currentIndexKey: CodingKey {
        return DefaultKey(intValue: currentIndex)!
    }

    private mutating func nextValue(_ type: Any.Type) throws -> Value {
        guard !isAtEnd else {
            throw DecodingError.valueNotFoundError(forKey: currentIndexKey,
                                                   of: type,
                                                   in: self)
        }
        defer { currentIndex += 1 }
        return values[currentIndex]
    }

    private mutating func nonNullValue(_ type: Any.Type) throws -> Value {
        let value = try nextValue(type)

        if case .null = value {
            throw DecodingError.valueNotFoundError(forKey: currentIndexKey,
                                                   of: type,
                                                   in: self)
        }

        return value
    }

    private mutating func number<T: LosslessStringConvertible>() throws -> T {
        if case .number(let string) = try nonNullValue(T.self) {
            if let number = T(string) {
                return number
            } else {
                throw DecodingError.dataCorruptedError(in: self,
                                                       debugDescription: "Can't parse \(T.self)")
            }
        } else {
            throw DecodingError.typeMismatchError(forKey: currentIndexKey,
                                                  of: T.self,
                                                  in: self)
        }
    }

    private mutating func decoder() throws -> Decoder {
        return try ActualDecoder(codingPath: codingPath + [currentIndexKey], value: nextValue(Any.self))
    }

    private mutating func decimal() throws -> Decimal {
        if case .number(let string) = try nonNullValue(Decimal.self) {
            if let number = Decimal(string: string) {
                return number
            } else {
                throw DecodingError.dataCorruptedError(in: self,
                                                       debugDescription: "Can't parse \(Decimal.self)")
            }
        } else {
            throw DecodingError.typeMismatchError(forKey: currentIndexKey,
                                                  of: Decimal.self,
                                                  in: self)
        }
    }
}

extension UnkeyedContainer: UnkeyedDecodingContainer {

    var count: Int? {
        return values.count
    }

    var isAtEnd: Bool {
        return values.count <= currentIndex
    }

    mutating func decodeNil() throws -> Bool {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Any.self, .init(codingPath: codingPath + [DefaultKey(intValue: currentIndex)!], debugDescription: ""))
        }
        if case .null = values[currentIndex] {
            currentIndex += 1
            return true
        } else {
            return false
        }
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        if case .boolean(let bool) = try nonNullValue(type) {
            return bool
        } else {
            throw DecodingError.typeMismatch(Bool.self, .init(codingPath: codingPath + [DefaultKey(intValue: currentIndex)!], debugDescription: ""))
        }
    }

    mutating func decode(_ type: String.Type) throws -> String {
        if case .string(let string) = try nonNullValue(type) {
            return string
        } else {
            throw DecodingError.typeMismatch(String.self, .init(codingPath: codingPath + [DefaultKey(intValue: currentIndex)!], debugDescription: ""))
        }
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        return try number()
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        return try number()
    }

    mutating func decode(_ type: Int.Type) throws -> Int {
        return try number()
    }

    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        return try number()
    }

    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        return try number()
    }

    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        return try number()
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        return try number()
    }

    mutating func decode(_ type: UInt.Type) throws -> UInt {
        return try number()
    }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try number()
    }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try number()
    }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try number()
    }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try number()
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if type == Decimal.self {
            return try decimal() as! T
        } else {
            return try T(from: decoder())
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        return try decoder().container(keyedBy: type)
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try decoder().unkeyedContainer()
    }

    mutating func superDecoder() throws -> Decoder {
        throw DecodingError.keyNotFound(DefaultKey(stringValue: "super")!, .init(codingPath: codingPath, debugDescription: ""))
    }
}
