//
// Scout
// Copyright (c) Alexis Bridoux 2020
// MIT license, see LICENSE file for details

import Foundation

extension String {

    // MARK: - Constants

    static var prefix: String { "\u{001B}[" }
    static var colorReset: String { "\(Self.prefix)39m" }
    static var reset: String { "\(Self.prefix)0m" }
    var mainColor: String { colored(with: 88) }

    // MARK: - Properties

    var bold: String { "\(Self.prefix)1;39m\(self)\(Self.prefix)22m" }
    var error: String { "\(Self.colorPrefix(91))\(self)\(Self.colorReset)"}

    /// Replace the `~` in the file path
    var replacingTilde: String {
        guard let tildeIndex = firstIndex(of: "~") else { return self }

        let userHomeDirectory = FileManager.default.homeDirectoryForCurrentUser.relativePath
        let afterIndex = index(after: tildeIndex)
        let pathAfterHome = String(self[afterIndex...])
        return userHomeDirectory + pathAfterHome
    }

    // MARK: - Functions

    static func colorPrefix(_ code: Int) -> String { "\(prefix)38;5;\(code)m" }

    func colored(with code: Int) -> String { "\(Self.colorPrefix(code))\(self)\(Self.reset)" }

    /// true if the string has the symbol as prefix and suffix
    func isEnclosed(by symbol: String) -> Bool { hasPrefix(symbol) && hasSuffix(symbol) }
}
