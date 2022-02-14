//
//  TestEntity.swift
//  SJSONDecoderTests
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

struct TestEntity: Decodable {
    let string: String
    let integer: Int
    let double: Double
    let decimal: Decimal
    let bool: Bool
    let date: Date
}

struct JustString: Decodable {
    let string: String
}
