//
//  Token.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class Token {
    
    // MARK: Properties
    
    private let separator: String
    private let tokens: Set<String>
    let tokenizedString: String
    
    // MARK: Initialization
    
    private init(tokens: Set<String>, separatedBy separator: String) {
        self.separator = separator
        self.tokens = tokens
        self.tokenizedString = tokens.sorted(by: { return $0 < $1 }).joined(separator: separator)
    }
    
    convenience init(string: String, separatedBy separator: String) {
        let stringTokens = Set(string.components(separatedBy: separator))
        self.init(tokens: stringTokens, separatedBy: separator)
    }
    
    // MARK: Token Functions
    
    func intersection(other: Token) -> Token {
        let intersectionTokens = tokens.intersection(other.tokens)
        return Token(tokens: intersectionTokens, separatedBy: separator)
    }
    
}
