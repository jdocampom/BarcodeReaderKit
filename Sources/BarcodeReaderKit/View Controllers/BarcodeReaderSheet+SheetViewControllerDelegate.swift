//
//  BarcodeReaderSheet+SheetViewControllerDelegate.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-19.
//

import Foundation
import UIKitExtensions

@available(iOS 15.0, *)
extension BarcodeReaderSheet: SheetViewControllerDelegate {
    
    /// Tells the delegate that the user has tapped the dismiss button.
    public func didTapDismissSheetViewController() {
        resultManager?.executeWhenViewWillDismissItself()
    }
    
    /// Tells the delegate that `viewWillAppear` is being called and asks what should it execute at that moment.
    public func shouldExecuteOnViewWillAppear() {
        resultManager?.executeWhenViewWillAppear()
    }
    
    /// Tells the delegate that `viewWillDisappear` is being called and asks what should it execute at that moment.
    public func shouldExecuteOnViewWillDisappear() {
        resultManager?.executeWhenViewWillDisappear()
    }
    
}
