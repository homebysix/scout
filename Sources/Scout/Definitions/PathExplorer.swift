//
// Scout
// Copyright (c) Alexis Bridoux 2020
// MIT license, see LICENSE file for details

import Foundation

/// Wrap different structs to explore several format: Json, Plist and Xml
public protocol PathExplorer: CustomStringConvertible, CustomDebugStringConvertible,
    ExpressibleByStringLiteral,
    ExpressibleByBooleanLiteral,
    ExpressibleByIntegerLiteral,
    ExpressibleByFloatLiteral
where
    StringLiteralType == String,
    BooleanLiteralType == Bool,
    IntegerLiteralType == Int,
    FloatLiteralType == Double {

    // MARK: - Properties

    /// Non-nil if the key is of the `String` type
    var string: String? { get }

    /// Non-nil if the key is of the `Bool` type
    var bool: Bool? { get }

    /// Non-nil if the key is of the `Integer` type
    var int: Int? { get }

    /// Non-nil if the key is of the `Real` type
    var real: Double? { get }

    /// String representation of value property (if value is nil this is empty String).
    var stringValue: String { get }

    var format: DataFormat { get }

    /// The path leading to the PathExplorer: firstKey.secondKey[index].thirdKey...
    var readingPath: Path { get }

    // MARK: - Initialization

    init(data: Data) throws
    init(value: Any)

    // MARK: - Functions

    // MARK: Get

    /// Get the key at the given path, specified as array
    /// - Throws: If the path is invalid (e.g. a key does not exist in a dictionary, or indicating an index on a non-array key)
    func get(_ path: Path) throws -> Self

    /// Get the key at the given path, specified as variadic `PathElementRepresentable`s
    /// - Throws: If the path is invalid (e.g. a key does not exist in a dictionary, or indicating an index on a non-array key)
    func get(_ path: PathElementRepresentable...) throws -> Self

    /// Get the key at the given path, specified as array
    /// - Throws: If the path is invalid (e.g. a key does not exist in a dictionary, or indicating an index on a non-array key), or the conversion is not possible
    func get<T: KeyAllowedType>(_ path: Path, as type: KeyType<T>) throws -> T

    /// Get the key at the given path, specified as variadic `PathElementRepresentable`s
    /// - Throws: If the path is invalid (e.g. a key does not exist in a dictionary, or indicating an index on a non-array key), or the conversion is not possible
    func get<T: KeyAllowedType>(_ path: PathElementRepresentable..., as type: KeyType<T>) throws -> T

    // MARK: Set

    /// Set the value of the key at the given path, specified as array
    /// - Throws: If the path is invalid (e.g. a key does not exist in a dictionary, or indicating an index on a non-array key)
    /// - note: The type of the `value` parameter will be automatically inferred. To force the `value`type, use the parameter `as type`
    mutating func set(_ path: Path, to newValue: Any) throws

    /// Set the value of the key at the given path, specified as array
    /// - parameter type: Try to force the conversion of the `value` parameter to the given type,
    /// throwing an error if the conversion is not possible
    /// - Throws: If the path is invalid (e.g. a key does not exist in a dictionary, or indicating an index on a non-array key)
    /// - note: The type of the `value` parameter will be automatically inferred.
    mutating func set<Type: KeyAllowedType>(_ path: Path, to newValue: Any, as type: KeyType<Type>) throws

    /// Set the value of the key at the given path, specified as array
    /// - Throws: If the path is invalid (e.g. a key does not exist in a dictionary, or indicating an index on a non-array key)
    /// - note: The type of the `value` parameter will be automatically inferred. To force the `value`type, use the parameter `as`
    mutating func set(_ path: PathElementRepresentable..., to newValue: Any) throws

    /// Set the value of the key at the given path, specified as variadic `PathElementRepresentable`s
    /// - parameter type: Try to force the conversion of the `value` parameter to the given type,
    /// throwing an error if the conversion is not possible
    /// - Throws: If the path is invalid (e.g. a key does not exist in a dictionary, or indicating an index on a non-array key)
    /// - note: The type of the `value` parameter will be automatically inferred.
    mutating func set<Type: KeyAllowedType>(_ path: PathElementRepresentable..., to newValue: Any, as type: KeyType<Type>) throws

    // - Set key name

    /// Set the name of the key at the given path, specified as array
    /// - Throws: If the path is invalid (e.g. a key does not exist in a dictionary)
    mutating func set(_ path: Path, keyNameTo newKeyName: String) throws

    /// Set the name of the key at the given path, specified as variadic `PathElementRepresentable`s
    /// - Throws: If the path is invalid (e.g. a key does not exist in a dictionary, or indicating an index on a non-array key)
    mutating func set(_ path: PathElementRepresentable..., keyNameTo newKeyName: String) throws

    // MARK: Delete

    /// Delete the key at the given path, specified as array.
    /// - parameter deleteIfEmpty: When `true`, the dictionary or array holding the value will be deleted too if empty after the key deletion
    /// - Throws: If the path is invalid (e.g. a key does not exist in a dictionary, or indicating an index on a non-array key)
    mutating func delete(_ path: Path, deleteIfEmpty: Bool) throws

    /// Delete the key at the given path,specified as variadic `PathElementRepresentable`s
    /// - parameter deleteIfEmpty: When `true`, the dictionary or array holding the value will be deleted too if empty after the key deletion
    /// - Throws: If the path is invalid (e.g. a key does not exist in a dictionary, or indicating an index on a non-array key)
    mutating func delete(_ path: PathElementRepresentable..., deleteIfEmpty: Bool) throws

    // MARK: Add

    /**
    Add a value at the given path, specified as array

    Any non existing key encoutered in the path will be created. For example, given the following Json:
    ```json
     {
       "people": {
         "Arnaud": {
           "height": 181,
           "age": 23,
           "hobbies": [
             "video games",
             "party",
             "tennis"
           ]
         }
     }
    ```
     The key "Tom" does not exist in the data. With the path ["people", "Tom", "age"], calling `json.add(175, to: path)`
     a new dictionary "Tom" will be added to "people", with one child key "age" and the given value:
     ```json
     {
       "people": {
        "Arnaud": {
          "height": 181,
          "age": 23,
          "hobbies": [
            "video games",
            "party",
            "tennis"
          ]
        },
         "Tom": {
           "height": 175,
         },
       }
     }
     ```
     With the path ["people", "Arnaud", "hobbies", 1], calling `json.add("football", to: path) will give
     ```json
     {
       "people": {
         "Arnaud": {
           "height": 181,
           "age": 23,
           "hobbies": [
             "video games",
             "football",
             "party",
             "tennis"
           ]
         }
     }
     ```
     - Throws:When trying to add a named key to an array, or a indexed key to a dictionary
     - note: To add a key at the end of an array, specify the index `-1`
    */
    mutating func add(_ newValue: Any, at path: Path) throws

    /**
    Add a value at the given path, specified as array

    Any non existing key encoutered in the path will be created. For example, given the following Json:
    ```json
     {
       "people": {
         "Arnaud": {
           "height": 181,
           "age": 23,
           "hobbies": [
             "video games",
             "party",
             "tennis"
           ]
         }
     }
    ```
     The key "Tom" does not exist in the data. With the path ["people", "Tom", "age"], calling `json.add(175, to: path)`
     a new dictionary "Tom" will be added to "people", with one child key "age" and the given value:
     ```json
     {
       "people": {
        "Arnaud": {
          "height": 181,
          "age": 23,
          "hobbies": [
            "video games",
            "party",
            "tennis"
          ]
        },
         "Tom": {
           "height": 175,
         },
       }
     }
     ```
     With the path ["people", "Arnaud", "hobbies", 1], calling `json.add("football", to: path) will give
     ```json
     {
       "people": {
         "Arnaud": {
           "height": 181,
           "age": 23,
           "hobbies": [
             "video games",
             "football",
             "party",
             "tennis"
           ]
         }
     }
     ```
     - parameter type: Try to force the conversion of the `value` parameter to the given type,
     throwing an error if the conversion is not possible
     - Throws:When trying to add a named key to an array, or a indexed key to a dictionary
     - note: To add a key at the end of an array, specify the index `-1`
    */
    mutating func add<Type: KeyAllowedType>(_ newValue: Any, at path: Path, as type: KeyType<Type>) throws

    /**
    Add a value at the given path, specified as variadic `PathElementRepresentable`s

    Any non existing key encoutered in the path will be created. For example, given the following Json:
    ```json
     {
       "people": {
         "Arnaud": {
           "height": 181,
           "age": 23,
           "hobbies": [
             "video games",
             "party",
             "tennis"
           ]
         }
     }
    ```
     The key "Tom" does not exist in the data. With the path ["people", "Tom", "age"], calling `json.add(175, to: path)`
     a new dictionary "Tom" will be added to "people", with one child key "age" and the given value:
     ```json
     {
       "people": {
        "Arnaud": {
          "height": 181,
          "age": 23,
          "hobbies": [
            "video games",
            "party",
            "tennis"
          ]
        },
         "Tom": {
           "height": 175,
         },
       }
     }
     ```
     With the path ["people", "Arnaud", "hobbies", 1], calling `json.add("football", to: path) will give
     ```json
     {
       "people": {
         "Arnaud": {
           "height": 181,
           "age": 23,
           "hobbies": [
             "video games",
             "football",
             "party",
             "tennis"
           ]
         }
     }
     ```
     - Throws:When trying to add a named key to an array, or a indexed key to a dictionary
     - note: To add a key at the end of an array, specify the index `-1`
    */
    mutating func add(_ newValue: Any, at path: PathElementRepresentable...) throws

    /**
    Add a value at the given path, specified as variadic `PathElementRepresentable`s

    Any non existing key encoutered in the path will be created. For example, given the following Json:
    ```json
     {
       "people": {
         "Arnaud": {
           "height": 181,
           "age": 23,
           "hobbies": [
             "video games",
             "party",
             "tennis"
           ]
         }
     }
    ```
     The key "Tom" does not exist in the data. With the path ["people", "Tom", "age"], calling `json.add(175, to: path)`
     a new dictionary "Tom" will be added to "people", with one child key "age" and the given value:
     ```json
     {
       "people": {
        "Arnaud": {
          "height": 181,
          "age": 23,
          "hobbies": [
            "video games",
            "party",
            "tennis"
          ]
        },
         "Tom": {
           "height": 175,
         },
       }
     }
     ```
     With the path ["people", "Arnaud", "hobbies", 1], calling `json.add("football", to: path) will give
     ```json
     {
       "people": {
         "Arnaud": {
           "height": 181,
           "age": 23,
           "hobbies": [
             "video games",
             "football",
             "party",
             "tennis"
           ]
         }
     }
     ```
     - parameter type: Try to force the conversion of the `value` parameter to the given type,
     throwing an error if the conversion is not possible
     - Throws:When trying to add a named key to an array, or a indexed key to a dictionary
     - note: To add a key at the end of an array, specify the index `-1`
    */
    mutating func add<Type: KeyAllowedType>(_ newValue: Any, at path: PathElementRepresentable..., as type: KeyType<Type>) throws

    // MARK: Conversion

    /// Try to convert the value held by the PathExplorer to the given type
    func convertValue<Type: KeyAllowedType>(to type: KeyType<Type>) throws -> Type

    // MARK: Export

    func exportData() throws -> Data
    func exportString() throws -> String
    func exportCSV(separator: String) throws -> String

    /// Replace the group values (array or dictionaries) sub values by a unique one
    /// holding a fold mark to be replaced when exporting the string
    mutating func fold(upTo level: Int)
}
