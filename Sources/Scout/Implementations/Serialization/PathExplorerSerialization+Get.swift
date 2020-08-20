//
// Scout
// Copyright (c) Alexis Bridoux 2020
// MIT license, see LICENSE file for details

import Foundation

extension PathExplorerSerialization {

    // MARK: - Array

    /// - parameter negativeIndexEnabled: If set to `true`, it is possible to get the last element of an array with the index `-1`
    /// - parameter detailedName: If`true`, when using a dictionary filter, the keys names will be changed to reflect the filtering
    func get(at index: Int, negativeIndexEnabled: Bool = true, detailedName: Bool = true) throws -> Self {
        let newValue: Any

        switch lastGroupElement {

        case .arraySlice:
            let array = try cast(value, as: .array, orThrow: .groupSampleConversionError(readingPath))
            newValue = try get(index: index, inArraySlice: array)

        case .dictionaryFilter:
            let dict = try cast(value, as: .dictionary, orThrow: .groupSampleConversionError(readingPath))
            newValue = try get(index: index, inDictionaryFilter: dict, detailedName: detailedName)

        case nil:
            newValue = try getSimple(index: index, negativeIndexEnabled: negativeIndexEnabled)
        }

        return PathExplorerSerialization(value: newValue, path: readingPath.appending(index))
    }

    func getSimple(index: Int, negativeIndexEnabled: Bool = true) throws -> Any {
        let array = try cast(value, as: .array, orThrow: .arraySubscript(readingPath))

        if index == .lastIndex, negativeIndexEnabled {
            if array.isEmpty {
                throw PathExplorerError.subscriptWrongIndex(path: readingPath, index: index, arrayCount: array.count)
            }
            return array[array.count - 1]
        } else {
            guard array.count > index, index >= 0 else {
                throw PathExplorerError.subscriptWrongIndex(path: readingPath, index: index, arrayCount: array.count)
            }
            return array[index]
        }
    }

    /// Get the given index in the array slice by browsing all the arrays in the slice
    func get(index: Int, inArraySlice array: ArrayValue) throws -> ArrayValue {
        var newArray = [Any]()

        for (elementIndex, element) in array.enumerated() {
            let path = readingPath.appending(.index(elementIndex))
            let pathExplorer = PathExplorerSerialization(value: element, path: path)
            let value = try pathExplorer.getSimple(index: index)
            newArray.append(value)
        }

        return newArray
    }

    /// Get the given index in the dictionary filter by browsing all the arrays in the slice
    /// - parameter detailedName: If`true`, when using a dictionary filter, the keys names will be changed to reflect the filtering
    func get(index: Int, inDictionaryFilter dictionary: DictionaryValue, detailedName: Bool = true) throws -> DictionaryValue {
        var newDict = DictionaryValue()

        try dictionary.forEach { (key, value) in
            let pathExplorer = PathExplorerSerialization(value: value, path: readingPath.appending(key))
            let newValue = try pathExplorer.getSimple(index: index)
            let newName = detailedName ? key + "[\(index)]" : key
            newDict[newName] = newValue
        }

        return newDict
    }

    // MARK: - Dictionary

    func get(for key: String, detailedName: Bool = true) throws -> Self {
        let newValue: Any

        switch lastGroupElement {

        case .arraySlice:
            let array = try cast(value, as: .array, orThrow: .arraySubscript(readingPath.appending(key)))
            newValue = try get(key: key, inArraySlice: array)

        case .dictionaryFilter:
            let dict = try cast(value, as: .dictionary, orThrow: .dictionarySubscript(readingPath))
            newValue = try get(key: key, inDictionaryFilter: dict, detailedName: detailedName)

        case nil:
            newValue = try getDictAndValueFor(key: key).value
        }

        return PathExplorerSerialization(value: newValue, path: readingPath.appending(key))
    }

    /// If `value` can be casted as a dictionary, and has the given key, return the dictionary and the key value in a tuple. Throws otherwise.
    func getDictAndValueFor(key: String) throws -> (dictionary: DictionaryValue, value: Any) {
        let dict = try cast(value, as: .dictionary, orThrow: .dictionarySubscript(readingPath))

        guard let value = dict[key] else {
            let bestMatch = key.bestJaroWinklerMatchIn(propositions: Set(dict.keys))
            throw PathExplorerError.subscriptMissingKey(path: readingPath, key: key, bestMatch: bestMatch)
        }

        return (dict, value)
    }

    /// Get the given key in the array slice by browsing all the dictionaries in the slice
    func get(key: String, inArraySlice array: ArrayValue) throws -> ArrayValue {
        var newArray = ArrayValue()

        for (index, element) in array.enumerated() {
            let path = readingPath.appending(.index(index))
            let pathExplorer = PathExplorerSerialization(value: element, path: path)
            let value = try pathExplorer.getDictAndValueFor(key: key).value
            newArray.append(value)
        }

        return newArray
    }

    /// Get the given key in the dictionary filter by browsing all the dictionaries in the filter
    /// - parameter detailedName: If`true`, when using a dictionary filter, the keys names will be changed to reflect the filtering
    func get(key: String, inDictionaryFilter dictionary: DictionaryValue, detailedName: Bool = true) throws -> DictionaryValue {
        var newDict = DictionaryValue()

        try dictionary.forEach { (keyValue, value) in
            let pathExplorer = PathExplorerSerialization(value: value, path: readingPath.appending(keyValue))
            let value = try pathExplorer.getDictAndValueFor(key: key).value
            let newName = detailedName ? keyValue + "." + key : keyValue
            newDict[newName] = value
        }

        return newDict
    }

    // MARK: - Count

    /// - Returns: The count of the array or dictionary if  `value` is an array or a dictionary
    func getChildrenCount() throws -> Self {
        switch lastGroupElement {
        case .arraySlice: return  try getChildrenCountInArraySlice()
        case .dictionaryFilter: return try getChildrenCountInDictionaryFilter()
        case nil: return try getChildrenCountSimple()
        }
    }

    func getChildrenCountSimple() throws -> Self {
        if let arrayValue = value as? ArrayValue {
            return PathExplorerSerialization(value: arrayValue.count, path: readingPath.appending(.count))
        } else if let dictValue = value as? DictionaryValue {
            return PathExplorerSerialization(value: dictValue.count, path: readingPath.appending(.count))
        } else {
            throw PathExplorerError.wrongUsage(of: .count, in: readingPath)
        }
    }

    func getChildrenCountInArraySlice() throws -> Self {
        let dict  = try cast(value, as: .array, orThrow: .arraySubscript(readingPath))
        var countsArray = [Int]()

        for (index, value) in dict.enumerated() {
            let pathExplorer = PathExplorerSerialization(value: value, path: readingPath.appending(index))
            guard let count = try pathExplorer.getChildrenCountSimple().int else {
                throw PathExplorerError.wrongUsage(of: .count, in: readingPath.appending(index))
            }
            countsArray.append(count)
        }
        return PathExplorerSerialization(value: countsArray, path: readingPath.appending(.count))
    }

    func getChildrenCountInDictionaryFilter() throws -> Self {
        let dict  = try cast(value, as: .dictionary, orThrow: .dictionarySubscript(readingPath))
        var countsDict = [String: Int]()

       try  dict.forEach { (key, value) in
            let path = readingPath.appending(key)
            let pathExplorer = PathExplorerSerialization(value: value, path: path)
            guard let count = try pathExplorer.getChildrenCountSimple().int else {
                throw PathExplorerError.wrongUsage(of: .count, in: path)
            }
            countsDict[key + "[#]"] = count
        }
        return PathExplorerSerialization(value: countsDict, path: readingPath.appending(.count))
    }

    // MARK: - Group

    func getSimple(_ groupSample: GroupSample) throws -> Self {
        switch groupSample {
        case .arraySlice(let bounds): return try getArraySliceSimple(within: bounds)
        case .dictionaryFilter(let pattern): return try getDictionaryFilterSimple(with: pattern)
        }
    }

    // MARK: Array slice

    /// Returns a slice of value is it is an array
    /// - parameter detailedName: If`true`, when using a dictionary filter, the keys names will be changed to reflect the filtering
    func getArraySlice(within bounds: Bounds, detailedName: Bool = true) throws -> Self {

        switch lastGroupElement {
        case .arraySlice:
            let slicedArray = try cast(value, as: .array, orThrow: .groupSampleConversionError(readingPath))
            return try get(.arraySlice(bounds), inArraySlice: slicedArray)

        case .dictionaryFilter:
            let dict = try cast(value, as: .dictionary, orThrow: .groupSampleConversionError(readingPath))
            return try get(.arraySlice(bounds), inDictionaryFilter: dict)

        case nil:
        return try getArraySliceSimple(within: bounds)
        }
    }

    func getArraySliceSimple(within bounds: Bounds) throws -> Self {
        let slice = PathElement.slice(bounds)
        let path = readingPath.appending(slice)
        let array = try cast(value, as: .array, orThrow: .wrongUsage(of: slice, in: path))

        let sliceRange = try bounds.range(lastValidIndex: array.count - 1, path: path)

        let newValue = Array(array[sliceRange])
        return PathExplorerSerialization(value: newValue, path: path)
    }

    func get(_ groupSample: GroupSample, inArraySlice array: ArrayValue) throws -> Self {
        var newArray = ArrayValue()

        for (index, element) in array.enumerated() {
            let path = readingPath.appending(index)
            let pathExplorer = PathExplorerSerialization(value: element, path: path)
            let slicedArray = try pathExplorer.getSimple(groupSample).value
            newArray.append(slicedArray)
        }

        return PathExplorerSerialization(value: newArray, path: readingPath.appending(groupSample.pathElement))
    }

    // MARK: Dictionary filter

    func getDictionaryFilter(with pattern: String) throws -> Self {
        switch lastGroupElement {
        case .arraySlice:
            let array = try cast(value, as: .array, orThrow: .groupSampleConversionError(readingPath))
            return try get(.dictionaryFilter(pattern), inArraySlice: array)

        case .dictionaryFilter:
            let dict = try cast(value, as: .dictionary, orThrow: .groupSampleConversionError(readingPath))
            return try get(.dictionaryFilter(pattern), inDictionaryFilter: dict)

        case nil:
            return try getDictionaryFilterSimple(with: pattern)
        }
    }

    func getDictionaryFilterSimple(with pattern: String) throws -> Self {
        let path = readingPath.appending(.filter(pattern))
        let regex = try NSRegularExpression(pattern: pattern, path: readingPath)

        if isArray {
            // allow the filter to be applied on string arrays
            let array = try cast(value, as: .array(.string), orThrow: .wrongUsage(of: .filter(pattern), in: path))
            let filteredArray = array.filter(regex.validate)
            return PathExplorerSerialization(value: filteredArray, path: path)
        }

        let dict = try cast(value, as: .dictionary, orThrow: .dictionarySubscript(path))
        let filteredDict = dict.filter { regex.validate($0.key) }
        return PathExplorerSerialization(value: filteredDict, path: path)
    }

    func get(_ groupSample: GroupSample, inDictionaryFilter dictionary: DictionaryValue, detailedName: Bool = true) throws -> Self {
        var newDict = DictionaryValue()

        try dictionary.forEach { (key, value) in
            let path = readingPath.appending(key)
            let pathExplorer = PathExplorerSerialization(value: value, path: path)
            let filteredDict = try pathExplorer.getSimple(groupSample).value
            let newName = detailedName ? key + groupSample.pathElement.description : key
            newDict[newName] = filteredDict
        }

        return PathExplorerSerialization(value: newDict, path: readingPath.appending(groupSample.pathElement))
    }

    // MARK: - General

    /// - parameter negativeIndexEnabled: If set to `true`, it is possible to get the last element of an array with the index `-1`
    /// - parameter detailedName: If`true`, when using a dictionary filter, the keys names will be changed to reflect the filtering
    func get(element: PathElement, negativeIndexEnabled: Bool = true, detailedName: Bool = true) throws -> Self {
        guard readingPath.last != .count else {
            throw PathExplorerError.wrongUsage(of: .count, in: readingPath)
        }

        switch element {
        case .key(let key): return try get(for: key, detailedName: detailedName)
        case .index(let index): return try get(at: index, negativeIndexEnabled: negativeIndexEnabled)
        case .count: return try getChildrenCount()
        case .slice(let bounds): return try getArraySlice(within: bounds, detailedName: detailedName)
        case .filter(let pattern): return try getDictionaryFilter(with: pattern)
        }
    }

    public func get(_ path: Path) throws -> Self {
        var currentPathExplorer = self

        try path.forEach { element in
            currentPathExplorer = try currentPathExplorer.get(element: element)
        }

        return currentPathExplorer
    }

    /// Explorer the path in parameter to find each `PathExplorer` in
    /// - Parameter path: The path to explore. Should not be empty
    /// - Throws: If the path is invalid
    /// - Returns: The explorers discovered, the path without the last element, and the last element
    func getExplorers(from path: Path) throws -> (explorers: [Self], path: Path, lastElement: PathElement) {
        assert(!path.isEmpty)

        var craftingPath = path
        let lastElement = craftingPath.removeLast()

        let explorers = try craftingPath.reduce([self]) { (explorers, element) in
            guard let currentExplorer = try explorers.last?.get(element: element, detailedName: false) else {
                return explorers // should not happen
            }

            return explorers + [currentExplorer]
        }

        return (explorers, craftingPath, lastElement)
    }
}
