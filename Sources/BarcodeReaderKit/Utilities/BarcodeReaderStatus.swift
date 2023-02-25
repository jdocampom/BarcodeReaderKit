//
//  BarcodeReaderStatus.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-18.
//

import Foundation

/// Represents the different status messages that the barcode reader can display during its operation.
public class BarcodeReaderStatus: NSObject {
    
    /// A `String` that represents the message to display when the barcode reader is preparing.
    let preparingMessage: String
    
    /// A `String` that represents the message to display when the barcode reader is ready to use.
    let readyMessage: String
    
    /// A `String` that represents the message to display when the barcode reader is searching for barcodes.
    let scanningMessage: String
    
    /// A `String` that represents the message to display when the barcode reader is processing a barcode.
    let processingMessage: String
    
    /// A `String` that represents the message to display when the barcode reader returned an error.
    let errorMessage: String
    
    /// A `String` that represents the message to display when the barcode reader is disables.
    let disabledMessage: String
    
    /// Creates a new value of type `BarcodeReaderStatus`.
    /// - Parameters:
    ///   - preparingMessage: A `String` that represents the message to display when the barcode reader is preparing.
    ///   - readyMessage: A `String` that represents the message to display when the barcode reader is ready to use.
    ///   - scanningMessage: A `String` that represents the message to display when the barcode reader is searching for barcodes.
    ///   - errorMessage: A `String` that represents the message to display when the barcode reader returned an error.
    ///   - disabledMessage: A `String` that represents the message to display when the barcode reader is disables.
    public init(
        preparingMessage: String,
        readyMessage: String,
        scanningMessage: String,
        processingMessage: String,
        errorMessage: String,
        disabledMessage: String
    ) {
        self.preparingMessage = preparingMessage
        self.readyMessage = readyMessage
        self.scanningMessage = scanningMessage
        self.processingMessage = processingMessage
        self.errorMessage = errorMessage
        self.disabledMessage = disabledMessage
    }
    
}
