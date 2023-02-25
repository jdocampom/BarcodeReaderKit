//
//  BarcodeReaderDelegate.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-18.
//

import Foundation

/// This protocol defines the methods that a delegate of a `BarcodeReader`object should implement.
public protocol BarcodeReaderDelegate: AnyObject {
    
    /// Tells the delegate that a barcode scan has been successful.
    /// - Parameter barcode: The barcode string that was scanned.
    func didScanBarcode(_ barcode: String)
    
    /// Tells the delegate that a barcode scan has failed.
    /// - Parameter barcode: A type representing an error value that can be thrown.
    func failedToScanBarcode(with error: Error)
    
    /// Tells the delegate that the user has tapped the dismiss button.
    func executeWhenViewWillDismissItself()
    
    /// Tells the delegate that `viewWillAppear` is being called and asks what should it execute at that moment.
    func executeWhenViewWillAppear()
    
    /// Tells the delegate that `viewDidAppear` is being called and asks what should it execute at that moment.
    func executeWhenViewHasAppeared()
    
    /// Tells the delegate that `viewWillDisappear` is being called and asks what should it execute at that moment.
    func executeWhenViewWillDisappear()
    
    /// Tells the delegate that `viewDidDisappear` is being called and asks what should it execute at that moment.
    func executeWhenViewHasDisappeared()
    
}
