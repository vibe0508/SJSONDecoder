//
//  SJSONDecoder.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

public class SJSONDecoder {

    public lazy var dateDecodingStrategy: DateDecodingStrategy = .timestamp

    public init() {}

    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        guard let string = String(data: data, encoding: .utf8) else {
            throw DecodingError
                .dataCorrupted(.init(codingPath: [],
                                     debugDescription: "Given data is not valid UTF-8 string"))
        }

        let session = DecodingSession(dateDecodingStrategy: dateDecodingStrategy)
        var parser = Parser(string: string)
        let decoder = try ActualDecoder(codingPath: [], session: session, value: parser.parse())
        return try T(from: decoder)
    }
}
