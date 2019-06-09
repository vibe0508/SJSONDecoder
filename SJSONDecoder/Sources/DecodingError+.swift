//
//  DecodingError+.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

protocol CodingPathHolder {
    var codingPath: [CodingKey] { get }
}

extension DecodingError {
    static func valueNotFoundError(forKey key: CodingKey? = nil,
                                   of type: Any.Type,
                                   in pathHolder: CodingPathHolder,
                                   debugDescription: String = "") -> DecodingError {
        return .valueNotFound(type,
                              .init(codingPath: pathHolder.codingPath + [key].compactMap { $0 },
                                    debugDescription: debugDescription))
    }

    static func typeMismatchError(forKey key: CodingKey? = nil,
                                  of type: Any.Type,
                                  in pathHolder: CodingPathHolder,
                                  debugDescription: String = "") -> DecodingError {
        return .typeMismatch(type,
                             .init(codingPath: pathHolder.codingPath + [key].compactMap { $0 },
                                   debugDescription: debugDescription))
    }
}
