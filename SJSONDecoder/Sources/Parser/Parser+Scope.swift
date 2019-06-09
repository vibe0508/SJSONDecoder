//
//  Parser+Scope.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

protocol ParserScope {
    func attemptModify(with char: Character) throws -> Parser.ScopeModificationResult
    func isValidChar(_ char: Character) -> Bool
    func modify(with char: Character) -> Parser.ScopeModificationResult
}

extension ParserScope {
    func attemptModify(with char: Character) throws -> Parser.ScopeModificationResult {
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
        private let chars: [Character]
        private let isEscaping: Bool

        init() {
            chars = []
            isEscaping = false
        }

        private init(chars: [Character], isEscaping: Bool) {
            self.chars = chars
            self.isEscaping = isEscaping
        }

        func isValidChar(_ char: Character) -> Bool {
            return true
        }

        func modify(with char: Character) -> ScopeModificationResult {
            switch (char, isEscaping) {
            case ("\"", false):
                return .returnToParent(value: .string(String(chars)), repeatChar: false)
            case ("\\", false):
                return .modifiedScope(StringScope(chars: chars, isEscaping: true))
            default:
                return .modifiedScope(StringScope(chars: chars + [char], isEscaping: false))
            }
        }
    }

    struct NumberScope: ParserScope {

        private static let numbers = Set("1234567890")
        private static let terminationChars = Set(" ,}]\n\t")

        private let chars: [Character]
        private let hasDot: Bool

        init(chars: [Character], hasDot: Bool = false) {
            self.chars = chars
            self.hasDot = hasDot
        }

        func isValidChar(_ char: Character) -> Bool {
            return ((char == "-" || char == "+") && chars.isEmpty)
                || (char == "." && !hasDot)
                || NumberScope.numbers.contains(char)
                || NumberScope.terminationChars.contains(char)
        }

        func modify(with char: Character) -> ScopeModificationResult {
            if !NumberScope.terminationChars.contains(char) && char != "." {
                return .modifiedScope(NumberScope(chars: chars + [char],
                                                  hasDot: hasDot))
            } else if char == "." {
                let appendingChars = Locale.current.decimalSeparator.flatMap { Array($0) } ?? ["."]
                return .modifiedScope(NumberScope(chars: chars + appendingChars,
                                                  hasDot: true))
            } else {
                return .returnToParent(value: .number(String(chars)),
                                       repeatChar: true)
            }
        }
    }

    struct LiteralScope: ParserScope {
        private let string: String

        init(startingChar: Character) {
            string = String(startingChar)
        }

        private init(string: String) {
            self.string = string
        }

        func isValidChar(_ char: Character) -> Bool {
            fatalError()
        }

        func modify(with char: Character) -> ScopeModificationResult {
            fatalError()
        }

        func attemptModify(with char: Character) throws -> ScopeModificationResult {
            let newString = string + String(char)

            guard ["true", "false", "null"].contains(where: {
                $0.hasPrefix(newString)
            }) else {
                try throwNotValidError()
            }

            if newString.count < 4 {
                return .modifiedScope(LiteralScope(string: newString))
            } else if let bool = Bool(newString) {
                return .returnToParent(value: .boolean(bool), repeatChar: false)
            } else if newString == "null" {
                return .returnToParent(value: .null, repeatChar: false)
            } else {
                return .modifiedScope(LiteralScope(string: newString))
            }
        }
    }
}
