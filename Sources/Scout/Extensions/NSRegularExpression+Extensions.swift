//
// Scout
// Copyright (c) Alexis Bridoux 2020
// MIT license, see LICENSE file for details

import Foundation

extension NSRegularExpression {

    // MARK: - Initialization

    convenience init(pattern: String, path: Path) throws {
        do {
            try self.init(pattern: pattern)
        } catch {
            throw PathExplorerError.wrongRegularExpression(pattern: pattern, in: path)
        }
    }

    // MARK: - Functions

    func matches(in string: String) -> [String] {
        let matches = self.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        return matches.map { String(string[$0.range]) }
    }

    /// Validate a string if the first match found by the regex is the overall string
    func validate(_ string: String) -> Bool {
        guard
            let firstMatch = firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)),
            firstMatch.range.length >= 0
        else {
            return false
        }

        if firstMatch.range.length == 0 {
            if string.isEmpty {
                return true
            } else {
                return false
            }
        }

        return string[firstMatch.range] == string
    }
}
