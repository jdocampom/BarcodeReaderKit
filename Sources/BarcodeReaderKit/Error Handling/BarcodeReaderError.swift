//
//  BarcodeReaderError.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-18.
//

import Foundation

internal enum BarcodeReaderError: Error, LocalizedError {
    
    case cameraPermissionNotGranted
    case failedCreatingCaptureDevice
    case failedCreatingFrameSupportingRange
    case failedCreatingDeviceInput
    case failedCreatingCameraInput
    case failedConfiguringCameraInput(Error)
    case failedToAddVideoOutput
    case failedToFindDeviceTorch
    case failedToConfigureDeviceTorch(Error)
    case failedToConfigureDelegate
    case failedToCreateSampleImageBuffer
    case failedToExtractDataFromBarcode
    case failedToVerifyBarcode
    case failedToVerifyScannerStatus
    case frameCannotBeProcessed
    case unavailableRevisionAlgorithm
    case visionFrameworkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .cameraPermissionNotGranted:
            return NSLocalizedString("Camera permission not granted.", comment: .empty)
        case .failedCreatingCaptureDevice:
            return NSLocalizedString("Could not create capture device.", comment: .empty)
        case .failedCreatingFrameSupportingRange:
            return NSLocalizedString("Failed to create frame supporting range.", comment: .empty)
        case .failedCreatingDeviceInput:
            return NSLocalizedString("Could not create device input.", comment: .empty)
        case .failedCreatingCameraInput:
            return NSLocalizedString("Could not create camera input.", comment: .empty)
        case .failedConfiguringCameraInput(let error):
            return error.localizedDescription
        case .failedToAddVideoOutput:
            return NSLocalizedString("Could not add video output into the current capture session.", comment: .empty)
        case .failedToFindDeviceTorch:
            return NSLocalizedString("Could not find hardware torch on this device.", comment: .empty)
        case .failedToConfigureDeviceTorch(let error):
            return error.localizedDescription
        case .failedToConfigureDelegate:
            return NSLocalizedString("Could not configure delegate.", comment: .empty)
        case .failedToCreateSampleImageBuffer:
            return NSLocalizedString("Could not create sample image buffer.", comment: .empty)
        case .failedToExtractDataFromBarcode:
            return NSLocalizedString("Could not extract data from barcode. This might happen because the barcode image is damaged or the device isn't pointing at any barcode at the moment.", comment: .empty)
        case .failedToVerifyBarcode:
            return NSLocalizedString("Could not verify data from barcode.", comment: .empty)
        case .failedToVerifyScannerStatus:
            return NSLocalizedString("Could not verify scanner status.", comment: .empty)
        case .frameCannotBeProcessed:
            return NSLocalizedString("Frame is set to be skipped. Returning...", comment: .empty)
        case .unavailableRevisionAlgorithm:
            return NSLocalizedString("Device is not running on iOS 15 or newer.", comment: .empty)
        case .visionFrameworkError(let error):
            return error.localizedDescription
        }
    }
    
}
