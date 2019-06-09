//
//  MockSingleValueContainer.swift
//  SJSONDecoderTests
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

struct MockSingleValueContainer: SingleValueDecodingContainer {
    let value: Any
    let codingPath: [CodingKey]

    private func convertedValue<T>() throws -> T {
        if let val = value as? T {
            return val
        } else {
            throw DecodingError.typeMismatch(T.self, .init(codingPath: codingPath, debugDescription: ""))
        }
    }

    func decodeNil() -> Bool {
        return false
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        return try convertedValue()
    }

    func decode(_ type: String.Type) throws -> String {
        return try convertedValue()
    }

    func decode(_ type: Double.Type) throws -> Double {
        return try convertedValue()
    }

    func decode(_ type: Float.Type) throws -> Float {
        return try convertedValue()
    }

    func decode(_ type: Int.Type) throws -> Int {
        return try convertedValue()
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        return try convertedValue()
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        return try convertedValue()
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        return try convertedValue()
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        return try convertedValue()
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        return try convertedValue()
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try convertedValue()
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try convertedValue()
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try convertedValue()
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try convertedValue()
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try convertedValue()
    }
}
