//
//  BarcodeProcessor.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-18.
//

import AVFoundation
import UIKit
import UIKitExtensions
import Vision

/// An object that performs barcode scanning and data validation for PDF417, Aztec, QR, Code-128 and Code-39 formats.
@available(iOS 13.0, *)
public final class BarcodeProcessor: NSObject {
    
    /// Represents the supported video orientation for scanning barcodes.
    public enum ScannerOrientation {
        
        /// Indicates that the scanner should automatically detect the orientation of the barcode being scanned.
        case automatic
        
        /// Indicates that the barcode should preferrably be scanned in portrait orientation.
        case portrait
        
        /// Indicates that the barcode should preferrably be scanned in landscape orientation.
        case landscape
    }
    
    /// Represents the status of a barcode scanner.
    public enum ScannerStatus {
        
        /// Indicates that the scanner is preparing for use. This could mean that it is initializing, warming up, or performing other necessary tasks.
        case preparing
        
        /// Indicates that the scanner is ready for use. This means that it is fully operational and can be used to scan barcodes.
        case ready
        
        /// Indicates that the scanner is currently in the process of scanning a barcode.
        case scanning
        
        /// Indicates that the scanner has found a barcode and its processing its payload data
        case processing
        
        /// Indicates that an error has occurred while using the scanner.
        case error
        
        /// Indicates that the scanner is disabled and cannot be used.
        case disabled
    }
    
    // MARK:  - Properties
    
    /// Barcode Processor Configuration Parameters
    /// - `frameInterval`: Indicates how manu frames should be ignored before processing the next one.
    /// - `validationLength`: Size of the validation array used to compute `validateBarcodeReading`.
    /// - `validationThreshold`: Minimum number of matches so a barcode read is considered as accurate and valid.
    private let parameters = (
        frameInterval: 10,
        validationLength: 5,
        validationThreshold: 3
    )
    
    /// CPU Optimization Variable used in `rootClassCaptureOutput`.
    private var frameCounter = 0
    
    /// Boolean Flag that indicates whether a barcode was found or not.
    private var canPerformScan = true
    
    /// Detected Barcode Symbology. Starts as being nil
    private var symbology: String? = nil
    
    /// The `UIView` object that is used to display the video preview from a `AVCaptureSession`.
    public private(set) var previewView: PreviewView!
    
    /// Array used for barcode validation. Starts as an empty String array and gets an element appended after each succesful scan.
    public private(set) var validationArray = [String]()
    
    /// A request that detects barcodes in an image. It returns an array of VNBarcodeObservation objects, one for each barcode it detects.
    public private(set) var barcodeRequest = VNDetectBarcodesRequest()
    
    /// Vision to AVFoundation coordinate transform.
    public private(set) var visionToAVFTransform = CGAffineTransform.identity
    
    /// An array of `CAShapeLayer` that represents the boxes that form the cutout.
    public internal(set) var boxLayer = [CAShapeLayer]()
    
    /// The barcode symbologies that the framework detects and supports.
    public private(set) var supportedSymbologies = [VNBarcodeSymbology]()
    
    /// The bounding box of the object that the request detects
    public private(set) var boundingBox = CGRect.zero
    
    /// Flag that indicates if the current frame should be processed or not. This action is performed for CPU usage optimisation purposes.
    private var shouldProcessFrame: Bool {
        return frameCounter % parameters.frameInterval == 0
    }
    
    /// String representation extracted from each barcode scan. Used for debugging purposes only.
    public internal(set) lazy var extractedStringFromBarcode: String = .empty
    
    /// Current status for the scanner
    public internal(set) lazy var status: ScannerStatus = .preparing
    
    /// Current video orientation.
    public internal(set) lazy var selectedOrientation: ScannerOrientation = .automatic
    
    // MARK: - Custom  Initialiser Methods
    
    /// Private initialiser to prevent this object from being instantiated anywhere else, leaving its functionality accesible only with the shared instance.
    public init(previewView: PreviewView) {
        super.init()
        self.previewView = previewView
        if #available(iOS 16.0, *) {
            barcodeRequest.revision = VNDetectBarcodesRequestRevision3
        } else if #available(iOS 15.0, *) {
            barcodeRequest.revision = VNDetectBarcodesRequestRevision2
        } else {
            barcodeRequest.revision = VNDetectBarcodesRequestRevision1
        }
    }
    
    // MARK: - Barcode Validation Methods
    
    /// Method that extracts the string representation for a given barcode thats being scanned with the device's Wide Angle camera.
    /// - Parameters:
    ///   - frame: Still frame from a giVen AVCaptureSession.
    /// - Returns: String representation of a ba
    private func extractDataFromBarcode(fromFrame frame: CVImageBuffer) throws ->  String {
        status = .scanning
        barcodeRequest.symbologies = supportedSymbologies
        let handler = VNImageRequestHandler(cvPixelBuffer: frame, orientation: .up, options: [:])
        do {
            try handler.perform([barcodeRequest])
            guard let results = barcodeRequest.results, let firstResult = results.first, let barcodeString = firstResult.payloadStringValue else {
                throw BarcodeReaderError.failedToExtractDataFromBarcode
            }
            guard let barcodeType = results.first?.symbology.rawValue else {
                throw BarcodeReaderError.failedToExtractDataFromBarcode
            }
            boundingBox = firstResult.boundingBox
            symbology = barcodeType
            guard shouldProcessFrame else {
                showBoundingRects(at: [boundingBox], color: .systemRed)
                throw BarcodeReaderError.frameCannotBeProcessed
            }
            showBoundingRects(at: [boundingBox], color: .systemGreen)
            Thread.sleep(forTimeInterval: 0.125)
            return cleanBarcodeString(barcodeString)
        } catch let error {
            throw BarcodeReaderError.visionFrameworkError(error)
        }
        
    }
    
    /// Checks if the last x ammount elements of a given array are identical given that this array has more than a certain determined quantity of elements.
    /// - Parameter array: Array that contains the string representation of the barcodes scanned.
    /// - Returns: Boolean flag that allows either to carry on with the application or retry scanning automatically.
    private func validateBarcodeReading(with barcode: String) -> Bool {
        canPerformScan = false
        validationArray.append(barcode)
        guard (validationArray.count == parameters.validationLength) else {
            if (validationArray.count > parameters.validationLength) { validationArray.removeAll() }
            restoreValidationStatus()
            return false
        }
        let testBatch = validationArray.suffix(parameters.validationThreshold)
        let didPassValidation = testBatch.dropFirst().allSatisfy({ $0 == validationArray.first })
        guard didPassValidation else {
            if (validationArray.count > parameters.validationLength) { validationArray.removeAll() }
            restoreValidationStatus()
            return false
        }
        validationArray.removeAll()
        restoreValidationStatus()
        return true
    }
    
    /// Restores default values for the validation and optimisation parameters.
    private func restoreValidationStatus() {
        canPerformScan = true
        frameCounter = 0
    }
    
    /// Removes any occurences of certain given characters from the barcode's String representation.
    /// - Parameter barcodeString: Barcode's String representation.
    /// - Returns: Cleaned String representation of the scanned barcode.
    private func cleanBarcodeString(_ barcodeString: String) -> String {
        let specialCharactersToRemove = ["\n", "\r", "\t", "\n\r", "\r\n"]
        let newString = barcodeString.removeAllOccurencesOf(specialCharactersToRemove)
        return newString
    }
    
    /// Configures all the symbologies that the barcode processor supports.
    /// - Parameter symbologies: An array of `VNBarcodeSymbology` objects that represents the barcode symbologies to be recognized.
    public func configureSymbologies(to symbologies: [VNBarcodeSymbology]) {
        supportedSymbologies = symbologies
    }
    
}

// MARK: - Barcode Processing

@available(iOS 13.0, *)
extension BarcodeProcessor {
    
    /// Notifies the delegate that a new video frame was written.
    /// - Parameters:
    ///   - output: The capture output object.
    ///   - sampleBuffer: A `CMSampleBuffer` object containing the video frame data and additional information about the frame, such as its format
    ///   and presentation time.
    ///   - connection: The connection from which the video was received.
    ///   - completion: A closure to execute when a valid barcode is found. Takes one parameter of type `String`.
    public func handleBarcodeResult(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection,
        completion: @escaping (String) -> Void
    ) throws {
        frameCounter += 1
        guard canPerformScan else {
            status = .error
            throw BarcodeReaderError.failedToVerifyScannerStatus
        }
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            status = .error
            throw BarcodeReaderError.failedToCreateSampleImageBuffer
        }
        do {
            let barcode = try extractDataFromBarcode(fromFrame: frame)
            print("BARCODE READER SHEET LOGS: Found barcode of type \(symbology ?? "Unknown").")
            print("Location: \(boundingBox).")
            print("Payload:<START>\(barcode)<END>")
            completion(barcode)
        } catch let error {
            print("BARCODE READER SHEET LOGS: Failed to process buffer. Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Bounding Box Drawing
    
    /// Displays bounding rectangles on a video preview layer.
    ///
    /// The rectangles are either in green (valid) or red (invalid). The function removes the previous rectangles and redraws the updated rectangles on the video
    /// preview layer.
    /// - Parameters:
    ///   - rects: An array of `CGRect` describing the positions for the valid text components.
    private func showBoundingRects(
        at positions: [CGRect],
        color: UIColor
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let layer = self.previewView.videoPreviewLayer
            self.removeBoxes()
            positions.forEach { item in
                let rect = layer.layerRectConverted(fromMetadataOutputRect: item.applying(self.visionToAVFTransform))
                self.draw(
                    rect: rect,
                    color: color.cgColor
                )
            }
        }
    }
    
    /// Draws a box on screen surrounding detected text fields.
    ///
    /// This method must be called on the main queue since it handles UI updates.
    /// - Parameters:
    ///   - rect: A structure that contains the location and dimensions of a rectangle.
    ///   - color: A set of components that define a color, with a color space specifying how to interpret them.
    private func draw(
        rect: CGRect,
        color: CGColor
    ) {
        let layer = CAShapeLayer()
        layer.opacity = 0.5
        layer.borderColor = color
        layer.borderWidth = 2.5
        layer.frame = rect
        boxLayer.append(layer)
        previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
    }
    
    /// Removes all drawn boxes.
    ///
    /// This method must be called on the main queue since it handles UI updates.
    private func removeBoxes() {
        boxLayer.forEach { $0.removeFromSuperlayer() }
        boxLayer.removeAll()
    }
    
}

