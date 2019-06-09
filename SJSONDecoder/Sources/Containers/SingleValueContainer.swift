//
//  SingleValueContainer.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

struct SingleValueContainer: CodingPathHolder {

    let codingPath: [CodingKey]
    let value: Value
    let session: DecodingSession

    init(codingPath: [CodingKey], value: Value, session: DecodingSession) {
        self.codingPath = codingPath
        self.value = value
        self.session = session
    }

    private func nonNullValue() throws -> Value {
        if case .null = value {
            throw DecodingError.valueNotFoundError(of: Bool.self,
                                                   in: self)
        }

        return value
    }

    private func number<T: LosslessStringConvertible>() throws -> T {
        if case .number(let string) = try nonNullValue() {
            if let number = T(string) {
                return number
            } else {
                throw DecodingError.dataCorruptedError(in: self,
                                                       debugDescription: "Can't parse \(T.self)")
            }
        } else {
            throw DecodingError.typeMismatchError(of: T.self,
                                                  in: self)
        }
    }

    private func decoder() throws -> Decoder {
        return ActualDecoder(codingPath: codingPath, session: session, value: value)
    }

    private func decimal() throws -> Decimal {
        if case .number(let string) = try nonNullValue() {
            if let number = Decimal(string: string) {
                return number
            } else {
                throw DecodingError.dataCorruptedError(in: self,
                                                       debugDescription: "Can't parse \(Decimal.self)")
            }
        } else {
            throw DecodingError.typeMismatchError(of: Decimal.self,
                                                  in: self)
        }
    }
}

extension SingleValueContainer: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        if case .null = value {
            return true
        } else {
            return false
        }
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        if case .boolean(let bool) = try nonNullValue() {
            return bool
        } else {
            throw DecodingError.typeMismatch(Bool.self, .init(codingPath: codingPath, debugDescription: ""))
        }
    }

    func decode(_ type: String.Type) throws -> String {
        if case .string(let string) = try nonNullValue() {
            return string
        } else {
            throw DecodingError.typeMismatch(String.self, .init(codingPath: codingPath, debugDescription: ""))
        }
    }

    func decode(_ type: Double.Type) throws -> Double {
        return try number()
    }

    func decode(_ type: Float.Type) throws -> Float {
        return try number()
    }

    func decode(_ type: Int.Type) throws -> Int {
        return try number()
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        return try number()
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        return try number()
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        return try number()
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        return try number()
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        return try number()
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try number()
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try number()
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try number()
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try number()
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if type == Decimal.self {
            return try decimal() as! T
        } else if type == Date.self {
            return try session.dateDecodingStrategy.transform(self) as! T
        } else {
            return try T(from: decoder())
        }
    }
}
