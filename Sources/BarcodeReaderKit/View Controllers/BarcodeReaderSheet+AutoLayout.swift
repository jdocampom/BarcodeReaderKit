//
//  BarcodeReaderSheet+AutoLayout.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-20.
//

import UIKit
import UIKitExtensions

@available(iOS 15.0, *)
extension BarcodeReaderSheet {
    
    // MARK: - Torch Button
    
    /// Adds `torchButton` into the view hierarchy and configures its auto layout constraints and  atributes.
    func configureTorchButton() {
        guard deviceHasTorch else { return }
        previewView.addSubview(torchButton)
        NSLayoutConstraint.activate([
            torchButton.widthAnchor.constraint(
                equalToConstant: BarcodeReaderConstants.buttonSize
            ),
            torchButton.heightAnchor.constraint(
                equalToConstant: BarcodeReaderConstants.buttonSize
            ),
            torchButton.leadingAnchor.constraint(
                equalTo: previewView.leadingAnchor,
                constant: BarcodeReaderConstants.horizontalPadding
            ),
            torchButton.topAnchor.constraint(
                equalTo: previewView.topAnchor,
                constant: BarcodeReaderConstants.verticalPadding
            )
        ])
        torchButton.addTarget(
            self,
            action: #selector(torchButtonTapped(_:)),
            for: .touchUpInside
        )
    }
    
    // MARK: - Status Label
    
    /// Adds `statusLabel` into the view hierarchy and configures its auto layout constraints and  atributes.
    func configureStatusLabel() {
        previewView.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.heightAnchor.constraint(
                equalToConstant: BarcodeReaderConstants.statusLabelHeight
            ),
            statusLabel.leadingAnchor.constraint(
                equalTo: previewView.leadingAnchor,
                constant: BarcodeReaderConstants.horizontalPadding
            ),
            statusLabel.trailingAnchor.constraint(
                equalTo: previewView.trailingAnchor,
                constant: -BarcodeReaderConstants.horizontalPadding
            ),
            statusLabel.bottomAnchor.constraint(
                equalTo: previewView.bottomAnchor,
                constant: -BarcodeReaderConstants.verticalPadding
            )
        ])
    }
    
    // MARK: - Settings Button
    
    /// Adds `settingsButton` into the view hierarchy and configures its auto layout constraints and  atributes.
    func configureSettingsButton() {
        previewView.addSubview(settingsButton)
        NSLayoutConstraint.activate([
            settingsButton.widthAnchor.constraint(
                equalToConstant: BarcodeReaderConstants.buttonSize
            ),
            settingsButton.heightAnchor.constraint(
                equalToConstant: BarcodeReaderConstants.buttonSize
            ),
            settingsButton.trailingAnchor.constraint(
                equalTo: previewView.trailingAnchor,
                constant: -BarcodeReaderConstants.horizontalPadding
            ),
            settingsButton.topAnchor.constraint(
                equalTo: previewView.topAnchor,
                constant: BarcodeReaderConstants.verticalPadding
            )
        ])
        settingsButton.addTarget(
            self,
            action: #selector(settingsButtonTapped(_:)),
            for: .touchUpInside
        )
    }
    
    // MARK: - Status Timer
    
    /// Creates and configures the target action for the local `Timer`instance of `statusTimer`.
    func configureStatusTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.statusTimer = Timer.scheduledTimer(
                withTimeInterval: 1 / 30,
                repeats: true
            ) { _ in
                self.updateStatusLabel()
            }
        }
    }
    
    /// Invalidates and removes from memory the local `Timer`instance of `statusTimer`.
    func invalidateStatusTimer() {
        statusTimer?.invalidate()
        statusTimer = nil
    }
    
    /// Updates the text displayed on `statusLabel` according to the current status of the `InkBarcodeReader` instance.
    private func updateStatusLabel() {
        switch barcodeProcessor.status {
        case .preparing:
            statusLabel.text = statusMessages.preparingMessage
        case .ready:
            statusLabel.text = statusMessages.readyMessage
        case .scanning:
            statusLabel.text = statusMessages.scanningMessage
        case .processing:
            statusLabel.text = statusMessages.processingMessage
        case .error:
            statusLabel.text = statusMessages.errorMessage
        case .disabled:
            statusLabel.text = statusMessages.disabledMessage
        }
    }
    
    /// Adds `orientationSelectorView` into the view hierarchy and configures its auto layout constraints and  atributes.
    func configureBarcodeOrientationView() {
        orientationSelectorView.isHidden = true
        previewView.addSubview(orientationSelectorView)
        NSLayoutConstraint.activate([
            orientationSelectorView.topAnchor.constraint(
                equalTo: previewView.topAnchor,
                constant: BarcodeReaderConstants.verticalPadding
            ),
            orientationSelectorView.leadingAnchor.constraint(
                equalTo: torchButton.trailingAnchor,
                constant: BarcodeReaderConstants.horizontalPadding
            ),
            orientationSelectorView.trailingAnchor.constraint(
                equalTo: settingsButton.leadingAnchor,
                constant: -BarcodeReaderConstants.horizontalPadding
            ),
            orientationSelectorView.heightAnchor.constraint(
                equalToConstant: BarcodeReaderConstants.buttonSize
            ),
        ])
    }
    
    /// Adds `orientationSelectorStackView` into the view hierarchy and configures its auto layout constraints and  atributes.
    func configureBarcodeOrientationStackView() {
        orientationSelectorView.addSubview(orientationSelectorStackView)
        orientationSelectorStackView.addArrangedSubview(automaticOrientationButton)
        orientationSelectorStackView.addArrangedSubview(verticalOrientationButton)
        orientationSelectorStackView.addArrangedSubview(horizontalOrientationButton)
        NSLayoutConstraint.activate([
            orientationSelectorStackView.topAnchor.constraint(
                equalTo: orientationSelectorView.topAnchor
            ),
            orientationSelectorStackView.leadingAnchor.constraint(
                equalTo: orientationSelectorView.leadingAnchor
            ),
            orientationSelectorStackView.trailingAnchor.constraint(
                equalTo: orientationSelectorView.trailingAnchor
            ),
            orientationSelectorStackView.bottomAnchor.constraint(
                equalTo: orientationSelectorView.bottomAnchor
            ),
        ])
        automaticOrientationButton.addTarget(
            self,
            action: #selector(changeOrientationButtonTapped(_:)),
            for: .touchUpInside
        )
        verticalOrientationButton.addTarget(
            self,
            action: #selector(changeOrientationButtonTapped(_:)),
            for: .touchUpInside
        )
        horizontalOrientationButton.addTarget(
            self,
            action: #selector(changeOrientationButtonTapped(_:)),
            for: .touchUpInside
        )
    }
    
    /// Configures the laser view for the barcode reader based on the selected orientation.
    func configureLaserView() {
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
    
    /// Adds `laserScopeView` into the view hierarchy and configures its auto layout constraints and  atributes.
    func configureAutomaticLaserView() {
        previewView.addSubview(laserScopeView)
        NSLayoutConstraint.activate([
            laserScopeView.leadingAnchor.constraint(
                equalTo: previewView.leadingAnchor,
                constant: BarcodeReaderConstants.laserViewPadding
            ),
            laserScopeView.trailingAnchor.constraint(
                equalTo: previewView.trailingAnchor,
                constant: -BarcodeReaderConstants.laserViewPadding
            ),
            laserScopeView.heightAnchor.constraint(
                equalTo: laserScopeView.widthAnchor
            ),
            laserScopeView.centerXAnchor.constraint(
                equalTo: previewView.centerXAnchor
            ),
            laserScopeView.centerYAnchor.constraint(
                equalTo: previewView.centerYAnchor
            )
        ])
    }
    
    /// Adds `horizontalLaserView` into the view hierarchy and configures its auto layout constraints and  atributes.
    func configurePortraitLaserView() {
        previewView.addSubview(horizontalLaserView)
        NSLayoutConstraint.activate([
            horizontalLaserView.heightAnchor.constraint(
                equalToConstant: BarcodeReaderConstants.laserViewWidth
            ),
            horizontalLaserView.leadingAnchor.constraint(
                equalTo: previewView.leadingAnchor,
                constant: BarcodeReaderConstants.horizontalPadding
            ),
            horizontalLaserView.trailingAnchor.constraint(
                equalTo: previewView.trailingAnchor,
                constant: -BarcodeReaderConstants.horizontalPadding
            ),
            horizontalLaserView.centerYAnchor.constraint(
                equalTo: previewView.centerYAnchor
            )
        ])
    }
    
    /// Adds `verticalLaserView` into the view hierarchy and configures its auto layout constraints and  atributes.
    func configureLandscapeLaserView() {
        previewView.addSubview(verticalLaserView)
        NSLayoutConstraint.activate([
            verticalLaserView.widthAnchor.constraint(
                equalToConstant: BarcodeReaderConstants.laserViewWidth
            ),
            verticalLaserView.topAnchor.constraint(
                equalTo: settingsButton.bottomAnchor,
                constant: BarcodeReaderConstants.verticalPadding
            ),
            verticalLaserView.bottomAnchor.constraint(
                equalTo: statusLabel.topAnchor,
                constant: -BarcodeReaderConstants.verticalPadding
            ),
            verticalLaserView.centerXAnchor.constraint(
                equalTo: previewView.centerXAnchor
            )
        ])
    }
    
}
