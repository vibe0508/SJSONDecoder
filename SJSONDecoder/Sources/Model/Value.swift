//
//  Value.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

enum Value {
    case string(String)
    case null
    case number(String)
    case boolean(Bool)
    indirect case array([Value])
    indirect case dictionary([String: Value])
}
