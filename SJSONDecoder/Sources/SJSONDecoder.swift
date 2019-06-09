//
//  SJSONDecoder.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

public class SJSONDecoder {
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        guard let string = String(data: data, encoding: .utf8) else {
            throw DecodingError
                .dataCorrupted(.init(codingPath: [],
                                     debugDescription: "Given data is not valid UTF-8 string"))
        }

        var parser = Parser(string: string)
        let decoder = try ActualDecoder(codingPath: [], value: parser.parse())
        return try T(from: decoder)
    }
}
