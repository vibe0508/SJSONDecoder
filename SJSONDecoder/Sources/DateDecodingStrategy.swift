//
//  DateDecodingStrategy.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

public struct DateDecodingStrategy {

    public static func withString(_ transform: @escaping (String) throws -> Date) -> DateDecodingStrategy {
        return DateDecodingStrategy(transform: { (container) -> Date in
            let string = try container.decode(String.self)
            do {
                return try transform(string)
            } catch DecodingError.dataCorrupted {
                throw DecodingError.dataCorruptedError(in: container,
                                                       debugDescription: "Can't parse string with date")
            }
        })
    }

    public static func withInt(_ transform: @escaping (Int) throws -> Date) -> DateDecodingStrategy {
        return DateDecodingStrategy(transform: { (container) -> Date in
            let integer = try container.decode(Int.self)
            do {
                return try transform(integer)
            } catch DecodingError.dataCorrupted {
                throw DecodingError.dataCorruptedError(in: container,
                                                       debugDescription: "Can't transform Int into date")
            }
        })
    }

    public static func withFormatter(_ dateFormatter: DateFormatter) -> DateDecodingStrategy {
        return .withString { (string) -> Date in
            if let date = dateFormatter.date(from: string) {
                return date
            } else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: ""))
            }
        }
    }

    public static var timestamp: DateDecodingStrategy {
        return withInt { miliseconds in
            return Date(timeIntervalSince1970: TimeInterval(miliseconds)/1000)
        }
    }

    public let transform: (SingleValueDecodingContainer) throws -> Date

    public init(transform: @escaping (SingleValueDecodingContainer) throws -> Date) {
        self.transform = transform
    }
}
