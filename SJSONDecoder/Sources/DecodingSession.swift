//
//  DecodingSession.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

class DecodingSession {
    let dateDecodingStrategy: DateDecodingStrategy

    init(dateDecodingStrategy: DateDecodingStrategy) {
        self.dateDecodingStrategy = dateDecodingStrategy
    }
}
