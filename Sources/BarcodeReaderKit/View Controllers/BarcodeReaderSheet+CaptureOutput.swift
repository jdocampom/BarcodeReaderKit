//
//  BarcodeReaderSheet+CaptureOutput.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-18.
//

import AVFoundation
import UIKit
import UIKitExtensions

@available(iOS 15.0, *)
extension BarcodeReaderSheet: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// Notifies the delegate that a new video frame was written.
    /// - Parameters:
    ///   - output: The capture output object.
    ///   - sampleBuffer: A `CMSampleBuffer` object containing the video frame data and additional information about the frame, such as its format
    ///   and presentation time.
    ///   - connection: The connection from which the video was received.
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        outputQueue.async { [weak self] in
            guard let self else { return }
            do {
                try self.barcodeProcessor.handleBarcodeResult(
                    output,
                    didOutput: sampleBuffer,
                    from: connection
                ) { barcode in
                    self.validateBarcodeReading(for: barcode)
                }
            } catch let error {
                print("BARCODE READER SHEET LOGS: Failed to process buffer. Error: \(error.localizedDescription).")
            }
        }
    }
    
    /// Dismisses the current instance of `BarcodeScannerViewController` given a valid barcode string.
    /// - Parameters:
    ///   - barcode: String representation of the barcode.
    private func validateBarcodeReading(for barcode: String) {
        guard barcodeProcessor.status != .preparing else {
            return
        }
        if isScanning {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.barcodeProcessor.status = .processing
                self.isScanning = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) {
                    HapticFeedback.success.vibrate()
                    self.dismissSheetViewController()
                    self.resultManager?.didScanBarcode(barcode)
                }
            }
        }
    }
    
}
