//
//  BarcodeReaderSheet+Torch.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-19.
//

import AVFoundation
import UIKit
import UIKitExtensions

@available(iOS 15.0, *)
public extension BarcodeReaderSheet {
    
    /// Turns the built-in hardware torch on and off, if available.
    /// - Parameter sender: The `UIButton` that triggered this action.
    @objc func torchButtonTapped(_ sender: UIButton) {
        switchTorch()
    }
    
    /// Turns the built-in hardware torch on and off depending on the current status, if available.
    private func switchTorch() {
        HapticFeedback.selection.vibrate()
        do {
            try switchTorchStatus()
            torchIsOn.toggle()
        } catch let error {
            print("BARCODE READER SHEET LOGS: Failed to switch torch status. Error: \(error.localizedDescription)")
            print(error.localizedDescription)
        }
    }
    
    /// Turns the built-in hardware torch off, if available.
    func turnOffTorch() {
        do {
            try switchTorchOff()
        } catch let error {
            print("BARCODE READER SHEET LOGS: Failed to turn off torch. Error: \(error.localizedDescription)")
        }
    }
    
    /// Switches device's torch on or off depending on the current status.
    private func switchTorchStatus() throws {
        guard let device = captureDevice else {
            throw BarcodeReaderError.failedCreatingCaptureDevice
        }
        guard device.hasTorch else {
            throw BarcodeReaderError.failedToFindDeviceTorch
        }
        do {
            try device.lockForConfiguration()
            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                } catch let error {
                    throw BarcodeReaderError.failedToConfigureDeviceTorch(error)
                }
            }
            device.unlockForConfiguration()
        } catch let error {
            throw BarcodeReaderError.failedToConfigureDeviceTorch(error)
        }
    }
    
    /// Turns off built-in LED torch.
    private func switchTorchOff() throws {
        guard let device = captureDevice else {
            throw BarcodeReaderError.failedCreatingCaptureDevice
        }
        guard device.hasTorch else {
            throw BarcodeReaderError.failedToFindDeviceTorch
        }
        do {
            try device.lockForConfiguration()
            device.torchMode = AVCaptureDevice.TorchMode.off
            device.unlockForConfiguration()
        } catch let error {
            throw BarcodeReaderError.failedToConfigureDeviceTorch(error)
        }
    }
    
}
