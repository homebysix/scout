import ArgumentParser
import Scout
import Foundation
import Lux

private let discussion =
"""

Notes
=====
- If the path is invalid, the program will retrun an error
- Enclose the value with sharp signs to change the key name: #keyName#
- Enclose the value with slash signs to force the value as a string: /valueAsString/ (useless with XML as XML only has string values)
- When accessing an array value by its index, use the index -1 to access to the last element

Examples
========

Given the following Json (as input stream or file):

{
  "people": {
    "Tom": {
      "height": 175,
      "age": 68,
      "hobbies": [
        "cooking",
        "guitar"
      ]
    },
    "Arnaud": {
      "height": 180,
      "age": 23,
      "hobbies": [
        "video games",
        "party",
        "tennis"
      ]
    }
  }
}

Examples
========

- Tom first hobby: "people.Tom.hobbies[0]" will output "cooking"

- Arnaud height: "people.Arnaud.height" will output "180"

- Tom first hobby: "people.Tom.hobbies[-1]" will output Tom last hobby: "guitar"
"""

struct ReadCommand: ParsableCommand {

    // MARK: - Constants

    static let configuration = CommandConfiguration(
        commandName: "read",
        abstract: "Read a value at a given path",
        discussion: discussion)

    // MARK: - Properties

    @Argument(help: "Path in the data where to read the key value")
    var readingPath: Path?

    @Option(name: [.short, .customLong("input")], help: "A file path from which to read the data")
    var inputFilePath: String?

    // MARK: - Functions

    func run() throws {

        if let filePath = inputFilePath {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath.replacingTilde))
            try read(from: data)
        } else {
            let streamInput = FileHandle.standardInput.readDataToEndOfFile()
            try read(from: streamInput)
        }
    }

    func read(from data: Data) throws {

        let readingPath = self.readingPath ?? Path()

        do {
            let (value, injector) = try readValue(at: readingPath, in: data)

            if value == "" {
                throw RuntimeError.noValueAt(path: readingPath.description)
            }

            let output = injector.inject(in: value)
            print(output)

        } catch let error as PathExplorerError {
            print(error.commandLineErrorDescription)
            return
        }
    }

    func readValue(at path: Path, in data: Data) throws -> (value: String, injector: Injector) {

        var injector: Injector
        var value: String

        if let json = try? PathExplorerFactory.make(Json.self, from: data) {
            let key = try json.get(path)
            value = key.stringValue != "" ? key.stringValue : key.description
            injector = JSONInjector(type: .plain)
        } else if let plist = try? PathExplorerFactory.make(Plist.self, from: data) {
            let key = try plist.get(path)
            value = key.stringValue != "" ? key.stringValue : key.description
            injector = PlistInjector(type: .plain)
        } else if let xml = try? PathExplorerFactory.make(Xml.self, from: data) {
            let key = try xml.get(path)
            value = key.stringValue != "" ? key.stringValue : key.description
            injector = XMLEnhancedInjector(type: .plain)
        } else {
            if let filePath = inputFilePath {
                throw RuntimeError.unknownFormat("The format of the file at \(filePath) is not recognized")
            } else {
                throw RuntimeError.unknownFormat("The format of the input stream is not recognized")
            }
        }

        return (value, injector)
    }
}
