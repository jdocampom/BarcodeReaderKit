//
//  BarcodeReaderSheetIdentifiers.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-20.
//

import Foundation

@objcMembers public class BarcodeReaderSheetIdentifiers: NSObject {
    
    /// An `Int` used to identify the `torchButtonTag` object through its `tag` property.
    public static let torchButtonTag = 36689899
    
    /// A `String` used to identify the `torchButtonTag` object through its `accesibilityIdentifier` property.
    public static let torchButtonAccesibilityID = "BARCODE_READER_TORCH_BUTTON"
    
    /// An `Int` used to identify the `settingsButton` object through its `tag` property.
    public static let settingsButtonTag = 37810865
    
    /// A `String` used to identify the `settingsButton` object through its `accesibilityIdentifier` property.
    public static let settingsButtonAccesibilityID = "BARCODE_READER_SETTINGS_BUTTON"
    
    /// A `String` used to store the value for the selected scanner orientation to.
    public static let scannerOrientationPreferenceKey = "BARCODE_READER_ORIENTATION_KEY"
    
    /// An `Int` used to identify the `automaticOrientationButton` object through its `tag` property.
    public static let automaticOrientationButtonTag = 45930220
    
    /// A `String` used to identify the `automaticOrientationButton` object through its `accesibilityIdentifier` property.
    public static let automaticOrientationButtonAccesibilityID = "BARCODE_READER_AUTO_ORIENTATION_BUTTON"
    
    /// A `String` used to set the scanner orientation to `.automatic`.
    public static let automaticOrientationPreferenceValue = "BARCODE_READER_AUTOMATIC_ORIENTATION_SELECTED"
    
    /// An `Int` used to identify the `verticalOrientationButton` object through its `tag` property.
    public static let portraitOrientationButtonTag = 33553743
    
    /// A `String` used to identify the `verticalOrientationButton` object through its `accesibilityIdentifier` property.
    public static let portraitOrientationButtonAccesibilityID = "BARCODE_READER_VERTICAL_ORIENTATION_BUTTON"
    
    /// A `String` used to set the scanner orientation to `.portrait`.
    public static let portraitOrientationPreferenceValue = "BARCODE_READER_PORTRAIT_ORIENTATION_SELECTED"
    
    /// An `Int` used to identify the `horizontalOrientationButton` object through its `tag` property.
    public static let landscapeOrientationButtonTag = 42299092
    
    /// A `String` used to identify the `horizontalOrientationButton` object through its `accesibilityIdentifier` property.
    public static let landscapeOrientationButtonAccesibilityID = "BARCODE_READER_HORIZONTAL_ORIENTATION_BUTTON"
    
    /// A `String` used to set the scanner orientation to `.landscape`.
    public static let landscapeOrientationPreferenceValue = "BARCODE_READER_LANDSCAPE_ORIENTATION_SELECTED"
    
    /// Private initialiser to prevent multiple instances from being created.
    private override init() {}
    
}
