//
//  Parser.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

struct Parser {

    enum ParserError: Error {
        case internalError
    }

    private var chars: [Character]

    private var currentIndex = 0
    private var scopesStack: [ParserScope] = []
    private var currentScope: ParserScope = NoScope()

    init(string: String) {
        chars = Array(string)
    }

    mutating func parse() throws -> Value {
        while currentIndex < chars.count {
            try apply(currentScope.attemptModify(with: chars[currentIndex]))
        }

        guard let value = (currentScope as? NoScope)?.value else {
            try NoScope().throwNotValidError()
        }

        return value
    }

    mutating private func apply(_ scopeChange: ScopeModificationResult) throws {
        switch scopeChange {
        case .modifiedScope(let scope):
            currentScope = scope
            currentIndex += 1
        case .noModification:
            currentIndex += 1
        case .newScope(let scope):
            scopesStack.append(currentScope)
            currentScope = scope
            currentIndex += 1
        case .returnToParent(let value, let repeatChar):
            guard let parent = scopesStack.popLast() as? ParserContainerScope else {
                try NoScope().throwNotValidError()
            }
            try apply(parent.accept(value))
            currentIndex -= repeatChar ? 1 : 0
        }
    }
}
