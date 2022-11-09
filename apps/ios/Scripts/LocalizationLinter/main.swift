#!/usr/bin/env xcrun --sdk macosx swift

//
//  Localization.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

// A script to clean string and code files for localization.

// Running the script with every Xcode build:
// Copy the script file to the project folder, than create a new `Run Script Phase`
// in `Build Phases` with the content "${SRCROOT}/Scripts/LocalizationLinter/Localization.swift"

// Running the script independently:
// In Terminal, navigate to top of the iOS app directory and then run: `./Scripts/LocalizationLinter/main.swift`
// Note: Use the "colorize" argument to output warning and error logs in color

// Operation flow:
// 1. Validates the file format of the base language strings file
// 2. Detects duplicate keys in the base language file
// 3. Detects keys used in code and storyboard files that are missing in the base language file
// 4. Detects uses of `NSLocalizedString()` in code files (optional)
// 5. Detects unused keys in the base language file

import Foundation

//---------------------------------------------------------------------//
// MARK: - Configuration
//---------------------------------------------------------------------//

struct Configuration {
    static let baseLanguageID = "en-US"
    static let languageFilesRelativeDirectoryPath = "GuideDogs/Assets/Localization/"
    static let codeFilesRelativeDirectoryPath = "GuideDogs/Code/"
    static let warnAboutNativeLocalizedStringUses = false
    
    static let coloredOutput = CommandLine.arguments.contains("colorize")
}

//---------------------------------------------------------------------//
// MARK: - Print Helpers
//---------------------------------------------------------------------//

struct OutputColors {
    /// Yellow warning color
    static let warning = "\u{001B}[0;33m"
    /// Red error color
    static let error = "\u{001B}[0;31m"
    /// An identifier to reset the colored output
    static let reset = "\u{001B}[m"
}

struct PrintLocation: CustomStringConvertible {
    let filePath: String
    let lineNumber: Int
    let columnNumber: Int
    
    var description: String {
        return filePath + ":" + String(lineNumber) + ":" + String(columnNumber)
    }
}

/// Prints a custom log to the console
///
/// - Parameters:
///     - string: The string to print.
///     - prefix: The prefix, i.g, "warning" or "error" (Xcode will mark them appropriately).
///     - location: An absolute path to the source file (Xcode will be able to jump to that location).
///     - color: The color to use, `nil` will use the default console color.
///
func printLog(_ string: String, prefix: String? = nil, location: PrintLocation? = nil, color: String? = nil) {
    var output = ""
    
    if let location = location {
        output = location.description + ": "
    }
    
    if let prefix = prefix {
        output += prefix + ": "
    }
    
    output += string

    if Configuration.coloredOutput, let color = color {
        output = color + output + OutputColors.reset
    }
    
    print(output)
}

func printWarning(_ string: String, location: PrintLocation? = nil) {
    printLog(string, prefix: "warning", location: location, color: OutputColors.warning)
}

func printError(_ string: String, location: PrintLocation? = nil) {
    printLog(string, prefix: "error", location: location, color: OutputColors.error)
}

//---------------------------------------------------------------------//
// MARK: - Extensions
//---------------------------------------------------------------------//

extension String {
    /// Returns true if the string is empty or contains only whitespaces and newlines
    var isBlank: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var nsrange: NSRange {
        return NSRange(self.startIndex..<self.endIndex, in: self)
    }
}

extension String {
    private static let newlineRegexPattern = "\n"
    
    /// Returns the line number for the text checking result, or `NSNotFound` if an error occurred
    func lineNumber(forTextCheckingResult result: NSTextCheckingResult) -> Int {
        guard let regex = try? NSRegularExpression(pattern: String.newlineRegexPattern) else {
            printError("Invalid regex pattern: " + String.newlineRegexPattern)
            return NSNotFound
        }
        
        let range = NSRange(location: 0, length: result.range.location)
        let numberOfMatches = regex.numberOfMatches(in: self, range: range)
        
        guard numberOfMatches > 0 else {
            return NSNotFound
        }
        
        return numberOfMatches + 1
    }
}

extension NSRegularExpression {
    static func matches(pattern: String, in string: String) -> [NSTextCheckingResult] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            printError("Invalid regex pattern: " + pattern)
            return []
        }
        return regex.matches(in: string, range: string.nsrange)
    }
    
    static func numberOfMatches(pattern: String, in string: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            printError("Invalid regex pattern: " + pattern)
            return 0
        }
        return regex.numberOfMatches(in: string, range: string.nsrange)
    }
}

extension FileManager {
    func stringContents(atPath path: String) -> String? {
        guard let data = contents(atPath: path) else {
            printError("Could not read data at path: \(path)")
            return nil
        }
        
        guard let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else {
            printError("Could not convert data to a string at path: \(path)")
            return nil
        }
        return content
    }
}

extension FileManager {
    func files(atPath path: String, includeSubfolders: Bool = false) -> [String] {
        if includeSubfolders {
            guard let enumerator = self.enumerator(atPath: path),
                  let files = enumerator.allObjects as? [String] else {
                printWarning("Could not get the content of the directory at path: \(path)")
                return []
            }
            return files
        }
        
        do {
            return try self.contentsOfDirectory(atPath: path)
        } catch {
            printWarning("Could not get the content of the directory at path: \(path), error: \(error.localizedDescription)")
            return []
        }
    }
    
    func files(withExtensions extensions: [String], atPath path: String, includeSubfolders: Bool = false) -> [String] {
        guard !extensions.isEmpty else { return [] }
        
        let files = self.files(atPath: path, includeSubfolders: includeSubfolders)
        
        let extensions = extensions.map { "." + $0 }
        
        return files.filter({ (file) -> Bool in
            for `extension` in extensions where file.hasSuffix(`extension`) {
                return true
            }
            return false
        })
    }
    
    func files(withExtension extension: String, atPath path: String, includeSubfolders: Bool = false) -> [String] {
        return self.files(withExtensions: [`extension`], atPath: path, includeSubfolders: includeSubfolders)
    }
}

extension FileManager {
    private static let languageFolderExtension = "lproj"
    
    /// Searches for folders of type `lproj` that contain `.strings` files
    /// - Note: `.strings` files should be named "Localizable.strings"
    func stringFiles(atPath path: String) -> [StringsFile] {
        let languageFolders = self.files(withExtension: FileManager.languageFolderExtension, atPath: path)
        
        guard !languageFolders.isEmpty else {
            printError("Could not locate files with extension \"\(FileManager.languageFolderExtension)\" at path: \(path)")
            return []
        }
        
        let stringFiles = languageFolders.compactMap { (languageFolder) -> StringsFile? in
            let languageID = languageFolder.replacingOccurrences(of: "." + FileManager.languageFolderExtension, with: "")
            let stringsFilePath = path + "/" + languageFolder + "/" + "Localizable.strings"
            return StringsFile(path: stringsFilePath, languageID: languageID)
        }
        
        return stringFiles
    }
    
    func codeFiles(withExtensions extensions: [String], atPath path: String) -> [CodeFile] {
        let codeFiles = self.files(withExtensions: extensions, atPath: path, includeSubfolders: true)
        
        guard !codeFiles.isEmpty else {
            printError("Could not locate code files at path: \(path)")
            return []
        }
        
        let codeFilesObjects = codeFiles.compactMap { (codeFile) -> CodeFile? in
            let codeFilePath = path + "/" + codeFile
            return CodeFile(path: codeFilePath)
        }
        
        return codeFilesObjects
    }
}

//---------------------------------------------------------------------//
// MARK: - Classes
//---------------------------------------------------------------------//

class File {
    
    // MARK: Properties
    
    let path: String
    let content: String
    
    var filename: String {
        return (path as NSString).lastPathComponent
    }
    
    // MARK: Initialization
    
    init(path: String, content: String) {
        self.path = path
        self.content = content
    }
    
}

//---------------------------------------------------------------------//
// MARK: -
//---------------------------------------------------------------------//

class StringsFile: File {
    
    // MARK: Types
    
    struct Translation: CustomStringConvertible, Hashable {
        let key: String
        let string: String
        let comment: String
        let wordCount: Int
        
        var description: String {
            return "<\(key): \(string)>"
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(key)
        }
    }
    
    struct FormatViolation {
        let violation: String
        let lineNumber: Int
    }
    
    struct FormatViolationRegex {
        let pattern: String
        let description: String
    }
    
    // MARK: Constants
    
    // Match:
    // /* comment */
    // "key" = "string";
    static let regexPattern = "\\/\\* (?<comment>.*?) \\*\\/\n\"(?<key>.*?)\" = \"(?<value>.*?)\";"
    
    static let wordCountRegex = "\\W*\\w+\\W*"
    
    static let formatViolationRegexPatterns = [
        // Matching: /*A or /*  A (more than one space)
        // Expected: /* A
        FormatViolationRegex(pattern: "(\\/\\*\\S|\\/\\*  )",
                             description: "Comment start (\"/*\") should be followed by one space (\"/* \")"),
        
        // Matching: A*/ or "A  */ (more than one space)
        // Expected: A */
        FormatViolationRegex(pattern: "(\\S\\*\\/|  \\*\\/)",
                             description: "Comment end (\"*/\") should be preceded by one space (\" */\")"),
        
        // Matching: "; followed by two newlines followed by a quotation marks
        // Expected: "; followed by two newlines followed by a forward-slash
        FormatViolationRegex(pattern: "\";\n\n\"",
                             description: "Missing comment"),
        
        // Matching: Anything but the expected
        // Expected: */\n" (comment end followed by a newline followed by a quotation marks)
        FormatViolationRegex(pattern: "\\*\\/(?!\n\")",
                             description: "Comments should be followed by the key-value pair in the following line"),
        
        // Matching: "=" or "= " or " =" or " = (extra spaces)" or "(extra spaces) = "
        // Expected: " = "
        FormatViolationRegex(pattern: "(\"=\"|\"= \"|\" =\"|\" = (?!\")|(?<!\") = \")",
                             description: "The assignment operator should be followed and preceded by one space (\" = \")"),
        
        // Matching: Anything but the expected
        // Expected: Vertical whitespace should be limited to a single empty line
        FormatViolationRegex(pattern: "\n\n\n",
                             description: "Vertical whitespace should be limited to a single empty line"),
        
        // Matching: "Quotation marks “within” a string"
        // Expected: "Quotation marks \"within\" a string"
        FormatViolationRegex(pattern: "“[^“”]*”",
                             description: "One or more invalid characters - Hexadecimal 201C and/or 201D. Replace these characters with a standard quotation mark that is escaped")
    ]
    
    // MARK: Properties
    
    let languageID: String
    let translations: [Translation]
    let keys: [String]
    let strings: [String]
    
    var duplicateKeys: [[String: [Translation]]] {
        let crossReference = Dictionary(grouping: translations, by: { $0.key })
        let duplicates = crossReference.filter { $1.count > 1 } // Filter to only those with multiple strings
        return duplicates.map { [$0.key: $0.value] }
    }
    
    var duplicateStrings: [[String: [Translation]]] {
        let crossReference = Dictionary(grouping: translations, by: { $0.string })
        let duplicates = crossReference.filter { $1.count > 1 } // Filter to only those with multiple keys
        return duplicates.map { [$0.key: $0.value] }
    }
    
    // MARK: Initialization
    
    init(path: String, content: String, languageID: String) {
        self.languageID = languageID
        self.translations = StringsFile.translations(fromContent: content)
        self.keys = self.translations.map { $0.key }
        self.strings = self.translations.map { $0.string }
        
        super.init(path: path, content: content)
    }
    
    convenience init?(path: String, languageID: String) {
        guard let content = FileManager.default.stringContents(atPath: path) else {
            printError("Could not extract content of file at path: \(path)")
            return nil
        }
        
        self.init(path: path, content: content, languageID: languageID)
    }
    
    // MARK: Type Methods
    
    static func translations(fromContent content: String) -> [Translation] {
        let matches = NSRegularExpression.matches(pattern: StringsFile.regexPattern, in: content)
        
        let translations = matches.compactMap { (match) -> Translation? in
            guard let commentRange = Range(match.range(withName: "comment"), in: content) else { return nil }
            guard let keyRange = Range(match.range(withName: "key"), in: content) else { return nil }
            guard let valueRange = Range(match.range(withName: "value"), in: content) else { return nil }
            
            let comment = String(content[commentRange])
            let key = String(content[keyRange])
            let value = String(content[valueRange])
            
            let wordCount = NSRegularExpression.numberOfMatches(pattern: wordCountRegex, in: value)
            
            return Translation(key: key, string: value, comment: comment, wordCount: wordCount)
        }
        
        return translations
    }
    
    static func formatViolations(content: String) -> [FormatViolation] {
        var violations = [FormatViolation]()
        
        for formatViolationRegex in StringsFile.formatViolationRegexPatterns {
            let matches = NSRegularExpression.matches(pattern: formatViolationRegex.pattern, in: content)
            
            matches.forEach { (match) in
                let lineNumber = content.lineNumber(forTextCheckingResult: match)
                violations.append(FormatViolation(violation: formatViolationRegex.description, lineNumber: lineNumber))
            }
        }
        
        return violations
    }
    
}

//---------------------------------------------------------------------//
// MARK: -
//---------------------------------------------------------------------//

class CodeFile: File {
    
    // MARK: Types
    
    /// One use of a localization function, such as `NSLocalizedString("string")`
    struct LocalizedStringInstance: CustomStringConvertible {
        /// The localization string key
        let key: String
        
        /// The localization function used, such as NSLocalizedString
        let function: String
        
        /// The line number
        let lineNumber: Int
        
        var description: String {
            return "\(function)(\"\(key)\")"
        }
    }

    struct DynamicLocalizedStringInstance: CustomStringConvertible {
        // matches: "\(any-string)"
        static let innerRegexPattern: String = #"\\\(.+?\)"#
        
        // matches: "any-string"
        static let replacementRegexPattern: String = #"[a-zA-Z-_]+"#
        
        /// Regex for the keys that fit this dynamic localized string instance
        let regex: NSRegularExpression

        /// The localization string key
        let key: String
        
        /// The localization function used, such as NSLocalizedString
        let function: String
        
        /// The line number
        let lineNumber: Int
        
        var description: String {
            return "\(function)(\"\(key)\")"
        }

        init?(dynamicKey: String, function: String, lineNumber: Int) {
            guard let innerRegex = try? NSRegularExpression(pattern: DynamicLocalizedStringInstance.innerRegexPattern) else {
                return nil
            }
            
            var newReg = dynamicKey.replacingOccurrences(of: ".", with: #"\."#)
            while let match = innerRegex.firstMatch(in: newReg, range: NSRange(newReg.startIndex ..< newReg.endIndex, in: newReg)),
                  let range = Range(match.range, in: newReg) {
                newReg = newReg.replacingCharacters(in: range, with: DynamicLocalizedStringInstance.replacementRegexPattern)
            }

            guard let reg = try? NSRegularExpression(pattern: newReg) else {
                return nil
            }

            self.regex = reg
            self.key = dynamicKey
            self.function = function
            self.lineNumber = lineNumber
        }
    }
    
    enum DynamicKeyIssue {
        case noTranslations(key: String)
        case oneTranslation(key: String)
    }
    
    // MARK: Type Properties
    
    // Match:
    // GDLocalizedString("key")
    // GDLocalizedString("key",
    // NSLocalizedString("key")
    // NSLocalizedString("key",
    static let localizationRegexPattern = "(?<func>(GD|NS)Localized(String|TextView))\\(\"(?<key>.*?)\"[\\)|,]"

    // Match:
    // GDLocalizedString("key.\(dynamic)")
    // GDLocalizedString("key.\(dynamic)",
    // NSLocalizedString("key.\(dynamic)")
    // NSLocalizedString("key.\(dynamic)",
    static let dynamicLocalizationRegexPattern = #"(?<func>(GD|NS)LocalizedString)\(\"(?<key>.*\\\(.+?\).*?)\"[\)|,]"#
    
    // Match:
    // <userDefinedRuntimeAttribute type="string" keyPath="localization" value="key"/>
    // <userDefinedRuntimeAttribute type="string" keyPath="accHintLocalization" value="key"/>
    // <userDefinedRuntimeAttribute type="string" keyPath="accLabelLocalization" value="key"/>
    
    static let storyboardLocalizationRegexPattern = #"(?<func>userDefinedRuntimeAttribute) type=\"string\" keyPath=\"(localization|accHintLocalization|accLabelLocalization)\" value=\"(?<key>.*?)\""#
    
    // MARK: Properties
    
    let isStoryboard: Bool
    
    let localizedStringInstances: [LocalizedStringInstance]
    let keys: [String]
    
    let dynamicLocalizedStringInstances: [DynamicLocalizedStringInstance]
    let dynamicKeys: [String]
    
    /// All uses of the `NSLocalizedString()` function
    var nslocalizedStringInstances: [LocalizedStringInstance] {
        return localizedStringInstances.filter { $0.function == "NSLocalizedString" }
    }
    
    // MARK: Initialization
    
    override init(path: String, content: String) {
        self.isStoryboard = path.hasSuffix("storyboard") || path.hasSuffix("xib")
        
        if self.isStoryboard {
            self.localizedStringInstances = CodeFile.localizedStringInstances(fromFileContent: content, regexPattern: CodeFile.storyboardLocalizationRegexPattern)
            self.dynamicLocalizedStringInstances = []
        } else {
            self.localizedStringInstances = CodeFile.localizedStringInstances(fromFileContent: content, regexPattern: CodeFile.localizationRegexPattern)
            self.dynamicLocalizedStringInstances = CodeFile.dynamicLocalizedStringInstances(fromFileContent: content)
        }
        
        self.keys = self.localizedStringInstances.map { $0.key }
        self.dynamicKeys = self.dynamicLocalizedStringInstances.map { $0.key }
        
        super.init(path: path, content: content)
    }
    
    convenience init?(path: String) {
        guard let content = FileManager.default.stringContents(atPath: path) else {
            printError("Could not extract content of file at path: \(path)")
            return nil
        }
        
        self.init(path: path, content: content)
    }
    
    // MARK: Instance Methods
    
    /// Returns all the keys used in the current code file that are not present in the strings file
    func missingKeys(from stringFile: StringsFile) -> Set<String> {
        return Set(keys).subtracting(dynamicKeys).subtracting(stringFile.keys)
    }
    
    func checkDynamicKeys(from stringFile: StringsFile) -> [DynamicKeyIssue] {
        return dynamicLocalizedStringInstances.compactMap { instance in
            let matches = stringFile.keys.flatMap {
                return instance.regex.matches(in: $0, range: NSRange($0.startIndex ..< $0.endIndex, in: $0))
            }
            
            if matches.count == 0 {
                return .noTranslations(key: instance.key)
            } else if matches.count == 1 {
                return .oneTranslation(key: instance.key)
            } else {
                return nil
            }
        }
    }
    
    // MARK: Type Methods
    
    static func localizedStringInstances(fromFileContent content: String, regexPattern: String) -> [LocalizedStringInstance] {
        let matches = NSRegularExpression.matches(pattern: regexPattern, in: content)
        
        let instances = matches.compactMap { (match) -> LocalizedStringInstance? in
            guard let keyRange = Range(match.range(withName: "key"), in: content) else { return nil }
            guard let funcRange = Range(match.range(withName: "func"), in: content) else { return nil }
            
            let key = String(content[keyRange])
            let function = String(content[funcRange])
            let lineNumber = content.lineNumber(forTextCheckingResult: match)

            return LocalizedStringInstance(key: key, function: function, lineNumber: lineNumber)
        }
        
        return instances
    }
    
    static func dynamicLocalizedStringInstances(fromFileContent content: String) -> [DynamicLocalizedStringInstance] {
        let matches = NSRegularExpression.matches(pattern: CodeFile.dynamicLocalizationRegexPattern, in: content)

        let instances = matches.compactMap { (match) -> DynamicLocalizedStringInstance? in
            guard let dynamicKeyRange = Range(match.range(withName: "key"), in: content) else { return nil }
            guard let funcRange = Range(match.range(withName: "func"), in: content) else { return nil }
            
            let dynamicKey = String(content[dynamicKeyRange])
            let function = String(content[funcRange])
            let lineNumber = content.lineNumber(forTextCheckingResult: match)

            return DynamicLocalizedStringInstance(dynamicKey: dynamicKey, function: function, lineNumber: lineNumber)
        }
        
        return instances
    }
    
}

//---------------------------------------------------------------------//
// MARK: - Execution
//---------------------------------------------------------------------//

printLog("Starting localization analysis")

let fileManager = FileManager.default
let currentDirectoryURL = URL(string: fileManager.currentDirectoryPath)!
let languageFilesDirectoryURL = currentDirectoryURL.appendingPathComponent(Configuration.languageFilesRelativeDirectoryPath, isDirectory: true)

printLog("Loading language files…")

var languageFiles = fileManager.stringFiles(atPath: languageFilesDirectoryURL.path)

guard !languageFiles.isEmpty else {
    printError("Could not locate language files")
    exit(1)
}

guard let baseLanguageFile = languageFiles.first(where: { $0.languageID == Configuration.baseLanguageID }) else {
    printError("Could not locate base language file at URL: \(languageFilesDirectoryURL)")
    exit(1)
}

languageFiles.sort {
    if $0.languageID == Configuration.baseLanguageID {
        return true
    } else {
        return $0.languageID < $1.languageID
    }
}

printLog("Found \(languageFiles.count) language files")

// Get the set of keys that we expect to appear in all translated
// string files after a translation pass is complete
let expectedKeys = Set(baseLanguageFile.translations
    .filter({ !$0.comment.contains("{Locked}") })
    .map({ $0.key }))

for languageFile in languageFiles {
    let totalWords = languageFile.translations.reduce(0, { return $0 + $1.wordCount })
    printLog("\(languageFile.languageID) (\(languageFile.translations.count) strings, \(totalWords) words\(languageFile.languageID == baseLanguageFile.languageID ? ", Base" : ""))")
    
    if CommandLine.arguments.contains("missing") {
        for missingKey in expectedKeys.subtracting(languageFile.keys) {
            printError("Missing translation for [\(missingKey)]")
        }
    }
}

printLog("Analyzing language files…")

let formatViolations = StringsFile.formatViolations(content: baseLanguageFile.content)
if formatViolations.isEmpty {
    printLog("Base language file does not contain format violations")
} else {
    formatViolations.forEach { (formatViolation) in
        let location = PrintLocation(filePath: baseLanguageFile.path, lineNumber: formatViolation.lineNumber, columnNumber: 0)
        printWarning("Strings file format violation in line \(formatViolation.lineNumber): \(formatViolation.violation)", location: location)
    }
}

//
// Ensure that invalid quotation marks (e.g. “”) are not used
//
let matches = NSRegularExpression.matches(pattern: "[“”]", in: baseLanguageFile.content)

matches.forEach { (match) in
    let lineNumber = baseLanguageFile.content.lineNumber(forTextCheckingResult: match)
    let location = PrintLocation(filePath: baseLanguageFile.path, lineNumber: lineNumber, columnNumber: 0)
    printError("Invalid character: Hexadecimal 201C or 201D. Replace these characters with a standard quotation mark that is escaped", location: location)
    exit(1)
}

//
// Ensure that there are no duplicate keys
//
if baseLanguageFile.duplicateKeys.isEmpty {
    printLog("Base language file does not contain duplicate keys")
} else {
    baseLanguageFile.duplicateKeys.forEach { (duplicate) in
        printError("Base language file contain duplicate key: \(duplicate)")
    }
}

printLog("Loading code files…")

let codeFilesDirectoryURL = currentDirectoryURL.appendingPathComponent(Configuration.codeFilesRelativeDirectoryPath, isDirectory: true)

let codeFiles = fileManager.codeFiles(withExtensions: ["swift", "m", "storyboard", "xib"], atPath: codeFilesDirectoryURL.path)

printLog("Analyzing \(codeFiles.count) code files…")

var allUsedKeys: Set<String> = []

codeFiles.forEach { (codeFile) in
    codeFile.missingKeys(from: baseLanguageFile).forEach({ (key) in
        printWarning("Missing translation: '\(codeFile.filename)' uses a localization key which is not found in the base language file (or the key format is invalid): \"\(key)\"")
    })
    
    codeFile.checkDynamicKeys(from: baseLanguageFile).forEach { issue in
        switch issue {
        case .noTranslations(let key):
            printWarning("Missing translation: '\(codeFile.filename)' uses a dynamic localization key which has no matching keys base language file (or the key format is invalid): \"\(key)\"")
            
        case .oneTranslation(let key):
            printWarning("Unnecessary dynamic key: '\(codeFile.filename)' uses a dynamic localization key which only has one matching key in the base language file. Consider replacing with a non-dynamic key: \"\(key)\"")
        }
    }
    
    if Configuration.warnAboutNativeLocalizedStringUses {
        codeFile.nslocalizedStringInstances.forEach({ (localizedStringInstance) in
            printWarning("NSLocalizedString violation: '\(codeFile.filename)' uses `NSLocalizedString` for key \"\(localizedStringInstance.key)\", consider using `GDLocalizedString`.")
        })
    }
    
    allUsedKeys = allUsedKeys.union(codeFile.keys)
    allUsedKeys = allUsedKeys.union(codeFile.dynamicKeys)
}

if CommandLine.arguments.contains("unused") {
    // Soundscape has several keys that are constructed and will therefore be detected as unused
    // translations by the code above. We filter out the prefixes for these strings in order to
    // avoid false positives
    let constructedKeyPrefixes = [
        "osm.tag.",
        "directions.traveling.",
        "directions.facing.",
        "directions.heading.",
        "directions.along.",
        "distance.format.",
        "whats_new."
    ]
    
    let unusedTranslations = baseLanguageFile.translations.filter { translation in
        guard !allUsedKeys.contains(translation.key) else {
            return false
        }
        
        return !constructedKeyPrefixes.contains(where: { translation.key.starts(with: $0) })
    }

    if unusedTranslations.isEmpty {
        printLog("Base language file does not contain unused keys")
    } else {
        printLog("Unused translations (\(unusedTranslations.count)):")

        unusedTranslations.sorted(by: { $0.key < $1.key })
            .forEach { (translation) in
                printWarning("Unused translation for [\(translation.key)]: \"\(translation.string)\"")
            }
    }
} else {
    printLog("Skipping unused keys check")
}

if CommandLine.arguments.contains("duplicates") {
    let dups = baseLanguageFile.duplicateStrings
    
    if dups.isEmpty {
        printLog("Base language file does not contain duplicate strings")
    } else {
        printLog("Duplicated string translations (\(dups.count)):")

        dups.compactMap({ $0.first })
            .sorted(by: { $0.key < $1.key })
            .forEach { dup in
                printWarning("Duplicate string: \"\(dup.key)\"")
                printWarning("                  \(dup.value.map({ $0.key }))")
            }
    }
} else {
    printLog("Skipping duplicate string check")
}
