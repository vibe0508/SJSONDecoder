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
        private var unicodeNumber: UInt16
        private var unicodeLengthToRead: Int

        init() {
            chars = []
            isEscaping = false
            unicodeNumber = 0
            unicodeLengthToRead = 0
        }

        func isValidChar(_ char: Character) -> Bool {
            return true
        }

        mutating func modify(with char: Character) -> ScopeModificationResult {
            if unicodeLengthToRead > 0 {
                let alphabet = "0123456789ABCDEF"
                if let stringIndex = alphabet.firstIndex(of: char) ?? alphabet.lowercased().firstIndex(of: char) {
                    let index = stringIndex.utf16Offset(in: alphabet)
                    unicodeNumber = unicodeNumber * 16 + UInt16(index)
                    unicodeLengthToRead -= 1
                    if unicodeLengthToRead == 0, let scalar = UnicodeScalar(unicodeNumber) {
                        chars.append(Character(scalar))
                    }
                    return .noModification
                } else {
                    unicodeLengthToRead = 0
                    //what to do when code is broken?
                }
            }
            switch (char, isEscaping) {
            case ("\"", false):
                return .returnToParent(value: .string(String(chars)), repeatChar: false)
            case ("\\", false):
                isEscaping = true
                return .noModification
            case ("n", true):
                chars.append("\n")
                isEscaping = false
                return .noModification
            case ("b", true):
                chars.append("\u{8}")
                isEscaping = false
                return .noModification
            case ("f", true):
                chars.append("\u{C}")
                isEscaping = false
                return .noModification
            case ("r", true):
                chars.append("\r")
                isEscaping = false
                return .noModification
            case ("t", true):
                chars.append("\t")
                isEscaping = false
                return .noModification
            case ("u", true):
                isEscaping = false
                unicodeLengthToRead = 4
                unicodeNumber = 0
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
