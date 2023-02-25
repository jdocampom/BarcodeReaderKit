//
//  PreviewView.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-18.
//

import AVFoundation
import UIKit

/// This class represents a custom `UIView` that displays the video preview from a `AVCaptureSession` instance.
public final class PreviewView: UIView {
    
    /// Returns the `AVCaptureVideoPreviewLayer` associated with this view.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }
    
    /// Returns and configures the `AVCaptureSession` instance for the `videoPreviewLayer`.
    var session: AVCaptureSession? {
        get { videoPreviewLayer.session }
        set { videoPreviewLayer.session = newValue }
    }
    
    /// Returns `AVCaptureVideoPreviewLayer.self` as the expected layer type for this view.
    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
}
