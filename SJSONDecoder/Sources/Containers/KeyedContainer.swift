//
//  KeyedContainer.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

struct KeyedContainer<Key: CodingKey>: CodingPathHolder {

    let codingPath: [CodingKey]
    let dict: [String: Value]
    let session: DecodingSession

    private func value(for key: Key) throws -> Value {
        guard let value = dict[key.stringValue] else {
            throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: ""))
        }
        return value
    }

    private func nonNullValue<T>(for key: Key, of type: T.Type) throws -> Value {
        guard let value = dict[key.stringValue] else {
            throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: ""))
        }

        if case .null = value {
            throw DecodingError.valueNotFoundError(forKey: key,
                                                   of: T.self,
                                                   in: self)
        }

        return value
    }

    private func number<T: LosslessStringConvertible>(for key: Key) throws -> T {
        if case .number(let string) = try nonNullValue(for: key, of: T.self) {
            if let number = T(string) {
                return number
            } else {
                throw DecodingError.dataCorruptedError(forKey: key,
                                                       in: self,
                                                       debugDescription: "Can't parse \(T.self)")
            }
        } else {
            throw DecodingError.typeMismatchError(forKey: key,
                                                  of: T.self,
                                                  in: self)
        }
    }

    private func decoder(for key: Key) throws -> Decoder {
        return try ActualDecoder(codingPath: codingPath + [key], session: session, value: value(for: key))
    }

    private func decimal(for key: Key) throws -> Decimal {
        if case .number(let string) = try nonNullValue(for: key, of: Decimal.self) {
            if let number = Decimal(string: string) {
                return number
            } else {
                throw DecodingError.dataCorruptedError(forKey: key,
                                                       in: self,
                                                       debugDescription: "Can't parse \(Decimal.self)")
            }
        } else {
            throw DecodingError.typeMismatchError(forKey: key,
                                                  of: Decimal.self,
                                                  in: self)
        }
    }
}

extension KeyedContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] {
        return dict.keys.compactMap { Key(stringValue: $0) }
    }

    func contains(_ key: Key) -> Bool {
        return dict[key.stringValue] != nil
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        if case .null = try value(for: key) {
            return true
        } else {
            return false
        }
    }

    func decode(_ type: Bool, forKey key: Key) throws -> Bool {
        if case .boolean(let bool) = try nonNullValue(for: key, of: Bool.self) {
            return bool
        } else {
            throw DecodingError.typeMismatchError(forKey: key,
                                                  of: Bool.self,
                                                  in: self)
        }
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        if case .string(let string) = try nonNullValue(for: key, of: String.self) {
            return string
        } else {
            throw DecodingError.typeMismatchError(forKey: key,
                                                  of: String.self,
                                                  in: self)
        }
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        return try number(for: key)
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        return try number(for: key)
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        return try number(for: key)
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        return try number(for: key)
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        return try number(for: key)
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        return try number(for: key)
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        return try number(for: key)
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        return try number(for: key)
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        return try number(for: key)
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        return try number(for: key)
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        return try number(for: key)
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        return try number(for: key)
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        if type == Decimal.self {
            return try decimal(for: key) as! T
        } else if type == Date.self {
            return try session.dateDecodingStrategy.transform(decoder(for: key).singleValueContainer()) as! T
        } else {
            return try T(from: decoder(for: key))
        }
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        return try decoder(for: key).container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return try decoder(for: key).unkeyedContainer()
    }

    func superDecoder() throws -> Decoder {
        throw DecodingError.keyNotFound(DefaultKey(stringValue: "super")!, .init(codingPath: codingPath, debugDescription: ""))
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        throw DecodingError.keyNotFound(DefaultKey(stringValue: "super")!, .init(codingPath: codingPath, debugDescription: ""))
    }
}
