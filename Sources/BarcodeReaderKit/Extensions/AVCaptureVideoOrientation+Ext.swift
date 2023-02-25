//
//  AVCaptureVideoOrientation+Ext.swift
//  BarcodeReader+Ext
//
//  Created by Juan Diego Ocampo on 2023-02-18.
//

import AVFoundation
import UIKit

/// This extension provides a convenience initializer that maps a `UIDeviceOrientation` to an `AVCaptureVideoOrientation`.
extension AVCaptureVideoOrientation {
    
    /// Creates an instance of `AVCaptureVideoOrientation` based on a given device orientation.
    /// - Parameter deviceOrientation: A `UIDeviceOrientation` value that represents the current orientation of the device.
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeRight
        case .landscapeRight:
            self = .landscapeLeft
        default:
            return nil
        }
    }
    
    /// Creates an instance of `AVCaptureVideoOrientation` based on a given interface orientation.
    /// - Parameter interfaceOrientation: A `UIInterfaceOrientation` value that represents the current orientation of the user interface.
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        default:
            return nil
        }
    }
    
}
