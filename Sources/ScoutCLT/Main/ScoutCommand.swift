//
// Scout
// Copyright (c) Alexis Bridoux 2020
// MIT license, see LICENSE file for details

import Foundation
import ArgumentParser
import Scout
import Lux

private let abstract =
"""
Read and modify values in specific format file or data. Currently supported: Json, Plist and Xml.
"""

private let discussion =
"""
To find advanced help and rich examples, please type `scout doc`.


Written by Alexis Bridoux.
\u{001B}[38;5;88mhttps://github.com/ABridoux/scout\u{001B}[0;0m
MIT license, see LICENSE file for details
"""

struct ScoutCommand: ParsableCommand {

    // MARK: - Constants

    static let configuration = CommandConfiguration(
            commandName: "scout",
            abstract: abstract,
            discussion: discussion,
            version: Scout.Version.current,
            subcommands: [
                ReadCommand.self,
                SetCommand.self,
                DeleteCommand.self,
                AddCommand.self,
                DocCommand.self,
                InstallCompletionScriptCommand.self],
            defaultSubcommand: ReadCommand.self)

    // MARK: - Functions

    static func output<T: PathExplorer>(_ output: String?, dataWith pathExplorer: T, colorise: Bool, level: Int? = nil, csvSeparator: String? = nil) throws {

        var csv: String?
        if let separator = csvSeparator {
            csv = try pathExplorer.exportCSV(separator: separator)
        }

        if let output = output?.replacingTilde {
            let fm = FileManager.default
            let contents = try csv?.data(using: .utf8) ?? pathExplorer.exportData()
            fm.createFile(atPath: output, contents: contents, attributes: nil)
            return
        }

        // remaining part to output the data

        // get the injector to inject color if necessary
        let injector: TextInjector
        switch pathExplorer.format {

        case .json:
            let jsonInjector = JSONInjector(type: .terminal)
            if let colors = try ScoutCommand.getColorFile()?.json {
                jsonInjector.delegate = JSONInjectorColorDelegate(colors: colors)
            }
            injector = jsonInjector

        case .plist:

            let plistInjector = PlistInjector(type: .terminal)
            if let colors = try ScoutCommand.getColorFile()?.plist {
                plistInjector.delegate = PlistInjectorColorDelegate(colors: colors)
            }
            injector = plistInjector

        case .xml:
            let xmlInjector = XMLEnhancedInjector(type: .terminal)
            if let colors = try ScoutCommand.getColorFile()?.xml {
                xmlInjector.delegate = XMLInjectorColorDelegate(colors: colors)
            }
            injector = xmlInjector
        }

        if let csvOutput = csv {
            print(csvOutput)
            return
        }

        // shadow variable to fold if necessary
        var pathExplorer = pathExplorer

        // fold if specified
        if let level = level {
            pathExplorer.fold(upTo: level)
        }

        var output = try pathExplorer.exportString()
        output = colorise ? injector.inject(in: output) : output
        print(output)
    }

    static func getColorFile() throws -> ColorFile? {
        let colorFileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".scout/Colors.plist")
        guard let data = try? Data(contentsOf: colorFileURL) else { return nil }

        return try PropertyListDecoder().decode(ColorFile.self, from: data)
    }
}
