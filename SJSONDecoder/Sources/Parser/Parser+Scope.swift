//
//  Parser+Scope.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

protocol ParserScope {
    mutating func attemptModify(with char: Character) throws -> Parser.ScopeModificationResult
    func isValidChar(_ char: Character) -> Bool
    mutating func modify(with char: Character) -> Parser.ScopeModificationResult
}

extension ParserScope {
    mutating func attemptModify(with char: Character) throws -> Parser.ScopeModificationResult {
        guard isValidChar(char) else {
            try throwNotValidError()
        }
        return modify(with: char)
    }

    func throwNotValidError() throws -> Never {
        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "The given data was not valid JSON."))
    }
}

extension Parser {
    enum ScopeModificationResult {
        case newScope(ParserScope)
        case modifiedScope(ParserScope)
        case noModification
        case returnToParent(value: Value, repeatChar: Bool)
    }

    struct StringScope: ParserScope {
        private var chars: [Character]
        private var isEscaping: Bool

        init() {
            chars = []
            isEscaping = false
        }

        func isValidChar(_ char: Character) -> Bool {
            return true
        }

        mutating func modify(with char: Character) -> ScopeModificationResult {
            switch (char, isEscaping) {
            case ("\"", false):
                return .returnToParent(value: .string(String(chars)), repeatChar: false)
            case ("\\", false):
                isEscaping = true
                return .noModification
            default:
                isEscaping = false
                chars.append(char)
                return .noModification
            }
        }
    }

    struct NumberScope: ParserScope {

        private static let numbers = Set("1234567890")
        private static let terminationChars = Set(" ,}]\n\t")

        private var chars: [Character]
        private var hasDot: Bool = false

        init(chars: [Character]) {
            self.chars = chars
        }

        func isValidChar(_ char: Character) -> Bool {
            return ((char == "-" || char == "+") && chars.isEmpty)
                || (char == "." && !hasDot)
                || NumberScope.numbers.contains(char)
                || NumberScope.terminationChars.contains(char)
        }

        mutating func modify(with char: Character) -> ScopeModificationResult {
            if char == "." {
                hasDot = true
                chars.append(char)
                return .noModification
            } else if !NumberScope.terminationChars.contains(char) {
                chars.append(char)
                return .noModification
            } else {
                return .returnToParent(value: .number(String(chars)),
                                       repeatChar: true)
            }
        }
    }

    struct LiteralScope: ParserScope {
        private var string: String

        init(startingChar: Character) {
            string = String(startingChar)
        }

        func isValidChar(_ char: Character) -> Bool {
            fatalError()
        }

        func modify(with char: Character) -> ScopeModificationResult {
            fatalError()
        }

        mutating func attemptModify(with char: Character) throws -> ScopeModificationResult {
            string.append(char)

            guard ["true", "false", "null"].contains(where: {
                $0.hasPrefix(string)
            }) else {
                try throwNotValidError()
            }

            if let bool = Bool(string) {
                return .returnToParent(value: .boolean(bool), repeatChar: false)
            } else if string == "null" {
                return .returnToParent(value: .null, repeatChar: false)
            } else {
                return .noModification
            }
        }
    }
}
