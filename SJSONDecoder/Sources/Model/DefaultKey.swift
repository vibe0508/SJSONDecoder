//
//  DefaultKey.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

struct DefaultKey: CodingKey {

    public var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        stringValue = "\(intValue)"
    }

    public var intValue: Int? {
        return Int(stringValue)
    }
}
