//
//  Parser+ContainerScope.swift
//  SJSONDecoder
//
//  Created by Вячеслав Бельтюков on 09/06/2019.
//  Copyright © 2019 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

protocol ParserContainerScope: ParserScope {
    func accept(_ value: Value) throws -> Parser.ScopeModificationResult
}

extension Parser {
    struct NoScope: ParserContainerScope {
        private static let allowedCharset = Set(" \n\t{[")

        let value: Value?

        init() {
            value = nil
        }

        private init(value: Value? = nil) {
            self.value = value
        }

        func isValidChar(_ char: Character) -> Bool {
            return NoScope.allowedCharset.contains(char)
        }

        func modify(with char: Character) -> ScopeModificationResult {
            switch char {
            case "{":
                return .newScope(DictionaryScope())
            case "[":
                return .newScope(ArrayScope())
            default:
                return .noModification
            }
        }

        func accept(_ value: Value) throws -> ScopeModificationResult {
            if self.value == nil {
                return .modifiedScope(NoScope(value: value))
            } else {
                try throwNotValidError()
            }
        }
    }
    
    struct ArrayScope: ParserContainerScope {

        private static let numbers = Set("0123456789")
        private static let literalChars = Set("falsetruenull")

        private let values: [Value]
        private let isSearchingValue: Bool

        init() {
            values = []
            isSearchingValue = true
        }

        init(values: [Value], isSearchingValue: Bool) {
            self.values = values
            self.isSearchingValue = isSearchingValue
        }

        func isValidChar(_ char: Character) -> Bool {
            return !(isSearchingValue && (char == "," || char == "]")) && char != "}"
        }

        func modify(with char: Character) -> ScopeModificationResult {
            if ArrayScope.literalChars.contains(char) {
                return .newScope(LiteralScope(startingChar: char))
            } else if ArrayScope.numbers.contains(char) {
                return .newScope(NumberScope(chars: [char]))
            } else if char == "\"" {
                return .newScope(StringScope())
            } else if char == "{" {
                return .newScope(DictionaryScope())
            } else if char == "[" {
                return .newScope(ArrayScope())
            } else if char == "]" {
                return .returnToParent(value: .array(values), repeatChar: false)
            } else {
                return .noModification
            }
        }

        func accept(_ value: Value) throws -> ScopeModificationResult {
            return .modifiedScope(ArrayScope(values: values + [value],
                                             isSearchingValue: false))
        }
    }

    struct DictionaryScope: ParserContainerScope {

        private enum Phase {
            private static let searchingKeyChars = Set(" \n\t\"}")
            private static let searchingColumnChars = Set(" \n\t:")
            private static let searchingValueChars = Set(" \n\t\"tfn1234567890-+")
            private static let searchingCommaChars = Set(" \n\t,}")

            case searchingKey
            case searchingColumn(key: String)
            case searchingValue(key: String)
            case searchingComma

            var allowedChars: Set<Character> {
                switch self {
                case .searchingKey:
                    return Phase.searchingKeyChars
                case .searchingColumn:
                    return Phase.searchingColumnChars
                case .searchingValue:
                    return Phase.searchingValueChars
                case .searchingComma:
                    return Phase.searchingCommaChars
                }
            }
        }

        private static let numbers = Set("-+1234567890")
        private static let literalStart = Set("ftn")

        private let values: [String: Value]
        private let phase: Phase

        init() {
            values = [:]
            phase = .searchingKey
        }

        private init(values: [String: Value], phase: Phase) {
            self.values = values
            self.phase = phase
        }

        func isValidChar(_ char: Character) -> Bool {
            return phase.allowedChars.contains(char)
        }

        func modify(with char: Character) -> ScopeModificationResult {
            switch (phase, char) {
            case (.searchingKey, "\""), (.searchingValue, "\""):
                return .newScope(StringScope())
            case (.searchingColumn(let key), ":"):
                return .modifiedScope(DictionaryScope(values: values, phase: .searchingValue(key: key)))
            case (.searchingValue, _) where DictionaryScope.numbers.contains(char):
                return .newScope(NumberScope(chars: [char]))
            case (.searchingValue, _) where DictionaryScope.literalStart.contains(char):
                return .newScope(LiteralScope(startingChar: char))
            case (.searchingValue, "["):
                return .newScope(ArrayScope())
            case (.searchingValue, "{"):
                return .newScope(DictionaryScope())
            case (.searchingComma, ","):
                return .modifiedScope(DictionaryScope(values: values, phase: .searchingKey))
            case (.searchingComma, "}"), (.searchingKey, "}"):
                return .returnToParent(value: .dictionary(values), repeatChar: false)
            default:
                return .noModification
            }
        }

        func accept(_ value: Value) throws -> ScopeModificationResult {
            if case .searchingValue(let key) = phase {
                var newValues = values
                newValues[key] = value
                return .modifiedScope(DictionaryScope(values: newValues, phase: .searchingComma))
            } else if case .string(let key) = value, case .searchingKey = phase, values[key] == nil {
                return .modifiedScope(DictionaryScope(values: values, phase: .searchingColumn(key: key)))
            } else {
                try throwNotValidError()
            }
        }
    }
}
