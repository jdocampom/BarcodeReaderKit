//
//  BarcodeReaderSheet+Settings.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-10.
//

import UIKit
import UIKitExtensions

// MARK:  - Settings Actions
@available(iOS 15.0, *)
public extension BarcodeReaderSheet {
    
    /// Displays (or hides) the `orientationSelectorView` and updates the `settingsButton` UI.
    /// - Parameter sender: The `UIButton` that triggered this action.
    @objc func settingsButtonTapped(_ sender: UIButton) {
        switchOrientationSelector()
    }
    
    /// Updates the current barcode orientation and refreshes the `laserView` UI.
    /// - Parameter sender: The `UIButton` that triggered this action.
    @objc func changeOrientationButtonTapped(_ sender: UIButton) {
        Task(priority: .userInitiated) {
            HapticFeedback.selection.vibrate()
            updateScannerOrientation(for: sender)
            updateOrientationSelectorButtonsUI()
            updateScannerOrientationUI()
        }
    }
    
    /// Displays (or hides) the `orientationSelectorView` and updates the `settingsButton` UI.
    func switchOrientationSelector() {
        HapticFeedback.selection.vibrate()
        settingsButtonIsSelected.toggle()
        updateOrientationViewUI()
        updateOrientationSelectorButtonsUI()
    }
    
    /// Updates the barcode reader orientation ans the UI for the `laserView` depending on its current orientation state.
    func updateOrientationSelectorButtonsUI() {
        switch barcodeProcessor.selectedOrientation {
        case .automatic:
            automaticOrientationButton.tintColor = .systemYellow
            verticalOrientationButton.tintColor = .white
            horizontalOrientationButton.tintColor = .white
        case .portrait:
            automaticOrientationButton.tintColor = .white
            verticalOrientationButton.tintColor = .systemYellow
            horizontalOrientationButton.tintColor = .white
        case .landscape:
            automaticOrientationButton.tintColor = .white
            verticalOrientationButton.tintColor = .white
            horizontalOrientationButton.tintColor = .systemYellow
        }
    }
    
    /// Displays (or hides) the `orientationSelectorView` with an animation.
    func updateOrientationViewUI() {
        if settingsButtonIsSelected {
            orientationSelectorView.showWithAnimation()
        } else {
            orientationSelectorView.hideWithAnimation()
        }
    }
    
    /// Updates the current selection for the barcode orientation to the new user selection.
    func updateScannerOrientation(for sender: UIButton) {
        switch sender.tag {
        case BarcodeReaderSheetIdentifiers.automaticOrientationButtonTag:
            UserDefaults.standard.set(
                BarcodeReaderSheetIdentifiers.automaticOrientationPreferenceValue,
                forKey: BarcodeReaderSheetIdentifiers.scannerOrientationPreferenceKey
            )
            barcodeProcessor.selectedOrientation = .automatic
        case BarcodeReaderSheetIdentifiers.portraitOrientationButtonTag:
            UserDefaults.standard.set(
                BarcodeReaderSheetIdentifiers.portraitOrientationPreferenceValue,
                forKey: BarcodeReaderSheetIdentifiers.scannerOrientationPreferenceKey
            )
            barcodeProcessor.selectedOrientation = .portrait
        case BarcodeReaderSheetIdentifiers.landscapeOrientationButtonTag:
            UserDefaults.standard.set(
                BarcodeReaderSheetIdentifiers.landscapeOrientationPreferenceValue,
                forKey: BarcodeReaderSheetIdentifiers.scannerOrientationPreferenceKey
            )
            barcodeProcessor.selectedOrientation = .landscape
        default:
            break
        }
    }
    
    /// Hides all laser views in the barcode reader
    func hideAllLaserViews() {
        laserScopeView.isHidden = true
        verticalLaserView.isHidden = true
        horizontalLaserView.isHidden = true
    }
    
    /// Hides all laser views in the barcode reader except for `laserScopeView`
    func showAutomaticLaserView() {
        laserScopeView.isHidden = false
        verticalLaserView.isHidden = true
        horizontalLaserView.isHidden = true
    }
    
    /// Hides all laser views in the barcode reader except for `horizontalLaserView`
    func showPortraitLaserView() {
        laserScopeView.isHidden = true
        verticalLaserView.isHidden = true
        horizontalLaserView.isHidden = false
    }
    
    /// Hides all laser views in the barcode reader except for `verticalLaserView`
    func showLandscapeLaserView() {
        laserScopeView.isHidden = true
        verticalLaserView.isHidden = false
        horizontalLaserView.isHidden = true
    }
    
    /// Updates the user interface of the barcode scanner to reflect the selected orientation.
    ///
    /// It hides all laser views, then based on the selected orientation, it will show either the `automaticLaserView`, the `portraitLaserView`, or the
    /// `landscapeLaserView`. It uses the `barcodeReader.selectedOrientation` property to determine the selected orientation.
    func updateScannerOrientationUI() {
        hideAllLaserViews()
        switch barcodeProcessor.selectedOrientation {
        case .automatic:
            showAutomaticLaserView()
        case .portrait:
            showPortraitLaserView()
        case .landscape:
            showLandscapeLaserView()
        }
    }
    
}
