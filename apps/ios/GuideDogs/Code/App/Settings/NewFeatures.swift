//
//  NewFeatures.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

struct FeatureInfo {
    
    // MARK: Properties
    
    private let titleKey: String
    private let descriptionKey: String
    private let accessibilityDescriptionKey: String
    private let imageFilename: String?
    private let buttonLabelKey: String?
    private let buttonAccessibilityHintKey: String?

    let hyperlinkStart: Int?
    let hyperlinkLength: Int?
    let hyperlinkURL: String?
    let version: VersionString
    let order: Int

    // MARK: Computed Properties

    var localizedTitle: String {
        return GDLocalizedString(titleKey)
    }
    
    var localizedDescription: String {
        return GDLocalizedString(descriptionKey)
    }
    
    var localizedAccessibilityDescription: String {
        return GDLocalizedString(accessibilityDescriptionKey)
    }
    
    var localizedImage: UIImage? {
        guard let imageFilename = imageFilename else {
            return nil
        }

        guard let localizedImage = UIImage(named: imageFilename + "_" + LocalizationContext.currentAppLocale.identifierHyphened) else {
            return UIImage(named: imageFilename + "_" + LocalizationContext.developmentLocale.identifierHyphened)
        }
        return localizedImage
    }
    
    var buttonLabel: String? {
        guard let buttonLabelKey = buttonLabelKey else {
            return nil
        }
        
        return GDLocalizedString(buttonLabelKey)
    }
    
    var buttonAccessibilityHint: String? {
        guard let buttonAccessibilityHintKey = buttonAccessibilityHintKey else {
            return nil
        }

        return GDLocalizedString(buttonAccessibilityHintKey)
    }
    
    // MARK: Initialization

    init(version: VersionString, properties: [String: String]) {
        titleKey = properties["Title"] ?? ""
        descriptionKey = properties["Description"] ?? ""
        accessibilityDescriptionKey = properties["AccessibilityDescription"] ?? ""
        hyperlinkStart = Int(properties["HyperlinkStart"] ?? "")
        hyperlinkLength = Int(properties["HyperlinkLength"] ?? "")
        hyperlinkURL = properties["HyperlinkURL"]
        imageFilename = properties["Image"]
        self.version = version
        order = Int(properties["Order"] ?? "-1")!
        buttonLabelKey = properties["ButtonLabel"]
        buttonAccessibilityHintKey = properties["ButtonAccessibilityHint"]
    }
    
}

// MARK: -

class NewFeatures {
    
    static var currentVersion: VersionString {
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        return VersionString(versionString)
    }

    static var lastDisplayedVersion: VersionString {
        return VersionString(SettingsContext.shared.newFeaturesLastDisplayedVersion)
    }
    
    private(set) var features: [VersionString: [FeatureInfo]] = [:]
    
    init() {
        guard let allFeaturesHistory = NewFeatures.allFeaturesHistory() else { return }
        
        let lastDisplayedVersion = NewFeatures.lastDisplayedVersion

        for (versionKey, featuresValue) in allFeaturesHistory {
            guard versionKey > lastDisplayedVersion else {
                continue
            }
            
            features[versionKey] = featuresValue
        }
    }
    
    static func allFeaturesHistory() -> [VersionString: [FeatureInfo]]? {
        guard let path = Bundle.main.path(forResource: "NewFeatures", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) as? [String: [[String: String]]] else {
                return nil
        }
        
        var allFeaturesHistory = [VersionString: [FeatureInfo]]()

        for (versionKey, featuresValue) in dict {
            var allVersionFeatures = [FeatureInfo]()
            
            let versionString = VersionString(versionKey)
            
            for feature in featuresValue {
                allVersionFeatures.append(FeatureInfo(version: versionString, properties: feature))
            }
            
            allFeaturesHistory[versionString] = allVersionFeatures.sorted(by: { $0.order < $1.order })
        }
        
        return allFeaturesHistory
    }
    
    func shouldShowNewFeatures() -> Bool {
        guard NewFeatures.lastDisplayedVersion < NewFeatures.currentVersion else {
            return false
        }
        
        guard features.contains(where: { $0.key > NewFeatures.lastDisplayedVersion }) else {
            return false
        }
        
        return true
    }
    
    func newFeaturesDidShow() {
        SettingsContext.shared.newFeaturesLastDisplayedVersion = NewFeatures.currentVersion.string
    }
}
