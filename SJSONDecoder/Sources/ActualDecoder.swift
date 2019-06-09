//
//  ActualDecoder.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

private extension Array {
    func asDictionary() -> [String: Element] {
        var dict: [String: Element] = [:]

        for (index, element) in enumerated() {
            dict["\(index)"] = element
        }

        return dict
    }
}

class ActualDecoder: Decoder {
    let codingPath: [CodingKey]
    let value: Value

    let session: DecodingSession
    var userInfo: [CodingUserInfoKey : Any] = [:]

    init(codingPath: [CodingKey], session: DecodingSession, value: Value) {
        self.value = value
        self.codingPath = codingPath
        self.session = session
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let dict: [String: Value]

        switch value {
        case .array(let values):
            dict = values.asDictionary()
        case .dictionary(let values):
            dict = values
        default:
            throw DecodingError.typeMismatch(Any.self, .init(codingPath: codingPath, debugDescription: ""))
        }

        return KeyedDecodingContainer(KeyedContainer(codingPath: codingPath, dict: dict, session: session))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        if case .array(let values) = value {
            return UnkeyedContainer(codingPath: codingPath, values: values, session: session)
        } else {
            throw DecodingError.typeMismatch(Any.self,
                                             .init(codingPath: codingPath, debugDescription: "Can't be represented with unkeyed container"))
        }
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return SingleValueContainer(codingPath: codingPath, value: value, session: session)
    }
}
