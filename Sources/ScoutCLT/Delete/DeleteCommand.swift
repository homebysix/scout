//
// Scout
// Copyright (c) Alexis Bridoux 2020
// MIT license, see LICENSE file for details

import ArgumentParser
import Scout
import Foundation

struct DeleteCommand: ParsableCommand {

    // MARK: - Constants

    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a value at a given path",
        discussion: "To find examples and advanced explanations, please type `scout doc -c delete`")

    // MARK: - Properties

    @Argument(help: "Paths to indicate the keys to be deleted")
    var readingPaths = [Path]()

    @Option(name: [.short, .customLong("input")], help: "A file path from which to read the data", completion: .file())
    var inputFilePath: String?

    @Option(name: [.short, .long], help: "Write the modified data into the file at the given path", completion: .file())
    var output: String?

    @Option(name: [.short, .customLong("modify")], help: "Read and write the data into the same file at the given path", completion: .file())
    var modifyFilePath: String?

    @Flag(help: "Highlight the ouput. --no-color or --nc to prevent it")
    var color = ColorFlag.color

    @Option(name: [.short, .long], help: "Fold the data at the given depth level")
    var level: Int?

    @Flag(name: [.short, .long], help: "When the deleted value leaves the array or dictionary holding it empty, delete it too")
    var recursive = false

    @Flag(name: [.customLong("csv")], help: "Convert the array data into CSV with the standard separator ';'")
    var csv = false

    @Option(name: [.customLong("csv-sep")], help: "Convert the array data into CSV with the given separator")
    var csvSeparator: String?

    // MARK: - Functions

    func run() throws {

        do {
            if let filePath = modifyFilePath ?? inputFilePath {
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath.replacingTilde))
                try delete(from: data)
            } else {
                let streamInput = FileHandle.standardInput.readDataToEndOfFile()
                try delete(from: streamInput)
            }
        }
    }

    func delete(from data: Data) throws {
        let output = modifyFilePath ?? self.output
        let separator = csvSeparator ?? (csv ? ";" : nil)

        if var json = try? Json(data: data) {

            try readingPaths.forEach { try json.delete($0, deleteIfEmpty: recursive) }
            try ScoutCommand.output(output, dataWith: json, colorise: color.colorise, level: level, csvSeparator: separator)

        } else if var plist = try? Plist(data: data) {

            try readingPaths.forEach { try plist.delete($0, deleteIfEmpty: recursive) }
            try ScoutCommand.output(output, dataWith: plist, colorise: color.colorise, level: level, csvSeparator: separator)

        } else if var xml = try? Xml(data: data) {

            try readingPaths.forEach { try xml.delete($0, deleteIfEmpty: recursive) }
            try ScoutCommand.output(output, dataWith: xml, colorise: color.colorise, level: level, csvSeparator: separator)

        } else {
            if let filePath = inputFilePath {
                throw RuntimeError.unknownFormat("The format of the file at \(filePath) is not recognized")
            } else {
                throw RuntimeError.unknownFormat("The format of the input stream is not recognized")
            }
        }
    }
}
