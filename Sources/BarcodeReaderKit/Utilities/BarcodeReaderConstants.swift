//
//  InkBarcodeReaderConstants.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-20.
//

import Foundation

/// Contains a set of constant values used by the `BarcodeReaderSheet`.
///
/// These values are used for padding, sizing, and positioning UI elements in the barcode reader interface.
enum BarcodeReaderConstants {
    
    /// A `CGFloat` value representing the vertical padding between UI elements.
    static let verticalPadding: CGFloat = 15
    
    /// A `CGFloat` value representing the horizontl padding between UI elements.
    static let horizontalPadding: CGFloat = 15
    
    /// A `CGFloat` value representing the size of the buttons in the barcode reader interface.
    static let buttonSize: CGFloat = 40
    
    /// A `CGFloat` value representing the padding between the laser view and the edge of the screen.
    static let laserViewPadding: CGFloat = 90
    
    /// A `CGFloat` value representing the width of the laser view used to scan the barcode.
    static let laserViewWidth: CGFloat = 2
    
    /// A `CGFloat` value representing the height of the status label that displays information to the user.
    static let statusLabelHeight: CGFloat = 30
    
}
