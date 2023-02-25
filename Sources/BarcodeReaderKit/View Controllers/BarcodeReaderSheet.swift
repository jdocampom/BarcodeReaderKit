//
//  BarcodeReaderSheet.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-18.
//

import AVFoundation
import UIKit
import UIKitExtensions
import Vision

@available(iOS 15.0, *)
@MainActor public final class BarcodeReaderSheet: SheetViewController {
    
    // MARK: - Properties
    
    /// A `UIColor` that object that specifies the color that will be used for the preview view while the session is loading label.
    @MainActor public var previewBackgroundColor: UIColor? {
        willSet(newValue) {
            previewView.backgroundColor = newValue
        }
    }
    
    /// A `UIFont` that object that specifies the font that will be used for the status label.
    @MainActor public var statusLabelFont: UIFont? {
        willSet(newValue) {
            statusLabel.font = newValue
        }
    }
    
    /// A `UIColor` that object that specifies the color that will be used for the title label.
    @MainActor public var statusLabelColor: UIColor? {
        willSet(newValue) {
            statusLabel.textColor = newValue
        }
    }
    
    /// The default error message title used in case of an unexpected error.
    public var defaultErrorMessageTitle = "Error"
    
    ///The default title for the OK button in an error message.
    ///
    ///This title is used as a fallback in case a more specific title is not provided.
    public var defaultOKButtonTitle = "OK"
    
    ///The default title for the Settings button in an error message.
    ///
    ///This title is used as a fallback in case a more specific title is not provided.
    public var defaultSettingsButtonTitle = "Settings"
    
    ///The error message to display when the app does not have permission to use the camera.
    ///
    ///This message is shown when attempting to launch the scanner and read barcodes without the necessary permission.
    public var cameraAuthorisationErrorMessage = "Camera usage permission is required in order to launch the scanner and read barcodes. Please open the Settings app and change privacy settings accordingly."
    
    /// The error message to display when something goes wrong while configuring the camera session.
    ///
    /// This message is shown when an error occurs while setting up the camera session for scanning barcodes.
    public var configurationErrorMessage = "Something went wrong configuring the camera session. Please try again."
    
    /// The error message to display when an unexpected error occurs during the scanning process.
    ///
    /// This message is shown when an error occurs while scanning barcodes that is not related to camera configuration or permission issues.
    public var runtimeErrorMessage = "Something went wrong. Please try again."
    
    /// The delegate object that object is responsible for managing user interactions and providing content for the bottom sheet.
    /// This object must adopt the `BarcodeReaderDelegate` protocol.
    public var resultManager: BarcodeReaderDelegate?
    
    /// An object  of type `BarcodeReaderStatus` that represents the status messages of the barcode reader
    public private(set) var statusMessages: BarcodeReaderStatus!
    
    /// A`Timer` object that is used to keep track of the status of the barcode scanning process. Defaults to `nil`.
    weak var statusTimer: Timer? = nil
    
    /// The `BarcodeReader` object, which is responsible for handling barcode reading and post-processing.
    var barcodeProcessor: BarcodeProcessor!
    
    /// The `Boolean` flag that indicates whether scanner is currently searching for barcodes or not. Defaults to `true`.
    var isScanning = true
    
    /// The `Boolean` flag that indicates whether the torch light is currently on or not. Defaults to `false`.
    var torchIsOn = false {
        willSet(newValue) {
            UIView.animate(withDuration: 0.25) { [weak self] in
                guard let self else { return }
                self.torchButton.tintColor = newValue ? .yellow : .white
                self.torchButton.setImage(newValue ? .turnOffTorch : .turnOnTorch, for: .normal)
            }
        }
    }
    
    /// The `Boolean` flag that indicates whether the settings button is currently selected or not. Defaults to `false`.
    var settingsButtonIsSelected = false {
        willSet(newValue) {
            UIView.animate(withDuration: 0.25) { [weak self] in
                guard let self else { return }
                self.settingsButton.tintColor = newValue ? .yellow : .white
            }
        }
    }
    
    /// The `Boolean` flag that determines whether the current device has torch hardware built-in or not.
    public var deviceHasTorch: Bool {
        guard let device = captureDevice else {
            return false
        }
        return device.hasTorch
    }
    
    // MARK: - UI Elements
    
    /// The `UIView` object that is used to display the video preview from a `AVCaptureSession` object for the current instance of
    /// `BarcodeReaderSheet`.
    private(set) lazy var previewView: PreviewView = {
        let view = PreviewView()
        view.backgroundColor = .clear
        view.insetsLayoutMarginsFromSafeArea = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// The `UILabel` object that is used to display the unsupported device status when `BarcodeScannerSheet` is used in a simulator.
    private(set) lazy var unsupportedDeviceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "Camera hardware is not available while using the simulator."
        label.textColor = .systemGray3
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    /// The `UILabel` object that is used to display the status of the scanner in the current instance of `BarcodeScannerSheet`.
    private(set) lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 1
        label.textColor = .label
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    /// The `UIButton` object that is used to switch the device's built-in torch hardware turn on and off, if available.
    private(set) lazy var torchButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .black.withAlphaComponent(0.25)
        button.tintColor = .white
        button.clipsToBounds = true
        button.layer.cornerRadius = 20
        button.setTitle(.empty, for: .normal)
        button.setImage(.turnOnTorch, for: .normal)
        button.accessibilityIdentifier = BarcodeReaderSheetIdentifiers.torchButtonAccesibilityID
        button.tag = BarcodeReaderSheetIdentifiers.torchButtonTag
        return button
    }()
    
    /// The `UIButton` object that is used to configure the device orientation of the current instance of `InkBarcodeScannerViewController`.
    private(set) lazy var settingsButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .black.withAlphaComponent(0.25)
        button.tintColor = .white
        button.clipsToBounds = true
        button.layer.cornerRadius = 20
        button.setTitle(.empty, for: .normal)
        button.setImage(.cameraSettings, for: .normal)
        button.accessibilityIdentifier = BarcodeReaderSheetIdentifiers.settingsButtonAccesibilityID
        button.tag = BarcodeReaderSheetIdentifiers.settingsButtonTag
        return button
    }()
    
    /// The `UIView` object that is used to display the buttons for configuring the scanner orientation in real time.
    private(set) lazy var orientationSelectorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.layer.zPosition = 1
        view.layer.cornerRadius = 10
        view.backgroundColor = .clear
        return view
    }()
    
    /// The `UIStackView` object that is used to display the buttons for configuring the scanner orientation in real time.
    lazy var orientationSelectorStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.clipsToBounds = true
        stackView.layer.cornerRadius = 5
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    /// The `UIButton` object that is used to configure the device orientation to automatic.
    private(set) lazy var automaticOrientationButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .black.withAlphaComponent(0.25)
        button.tintColor = .white
        button.setTitle(.empty, for: .normal)
        button.setImage(.cameraAutomaticOrientation, for: .normal)
        button.accessibilityIdentifier = BarcodeReaderSheetIdentifiers.automaticOrientationButtonAccesibilityID
        button.tag = BarcodeReaderSheetIdentifiers.automaticOrientationButtonTag
        return button
    }()
    
    /// The `UIButton` object that is used to configure the device orientation to portrait.
    private(set) lazy var verticalOrientationButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .black.withAlphaComponent(0.25)
        button.tintColor = .white
        button.setTitle(.empty, for: .normal)
        button.setImage(.cameraVerticalOrientation, for: .normal)
        button.accessibilityIdentifier = BarcodeReaderSheetIdentifiers.portraitOrientationButtonAccesibilityID
        button.tag = BarcodeReaderSheetIdentifiers.portraitOrientationButtonTag
        return button
    }()
    
    /// The `UIButton` object that is used to configure the device orientation to landscape.
    private(set) lazy var horizontalOrientationButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .black.withAlphaComponent(0.25)
        button.tintColor = .white
        button.setTitle(.empty, for: .normal)
        button.setImage(.cameraHorizontalOrientation, for: .normal)
        button.accessibilityIdentifier = BarcodeReaderSheetIdentifiers.landscapeOrientationButtonAccesibilityID
        button.tag = BarcodeReaderSheetIdentifiers.landscapeOrientationButtonTag
        return button
    }()
    
    /// The `UIView` object that is used to mimic the laser of a real barcode scanner when  the device orientation is set to automatic.
    private(set) lazy var laserScopeView: UIView = {
        let view = BarcodeReaderCornerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.lineWidth = 5
        return view
    }()
    
    /// The `UIView` object that is used to mimic the laser of a real barcode scanner when  the device orientation is set to portrait.
    private(set) lazy var horizontalLaserView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemRed
        view.clipsToBounds = true
        view.layer.cornerRadius = 2
        return view
    }()
    
    /// The `UIView` object that is used to mimic the laser of a real barcode scanner when  the device orientation is set to landscape.
    private(set) lazy var verticalLaserView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemRed
        view.clipsToBounds = true
        view.layer.cornerRadius = 2
        return view
    }()
    
    // MARK: - Capture Session Management
    
    /// The list  of `NSKeyValueObservation` objects registered for notifications when the value of a specified key path changes.
    internal var keyValueObservations = [NSKeyValueObservation]()
    
    /// An object that configures capture behavior and coordinates the flow of data from input devices to capture outputs.
    private(set) var session = AVCaptureSession()
    
    /// A `Bool` that indicates whether an `AVCaptureSession` is currently running or not.
    public internal(set) var isSessionRunning = false
    
    /// A `DispatchQueue` instance used to perform the tasks related to the capture session on a dedicated serial queue to prevent blocking the main thread.
    private(set) var sessionQueue = DispatchQueue(label: "BarcodeReaderSheet-sessionQueue")
    
    /// A `DispatchQueue` instance used to perform the tasks related to the capture session on a dedicated serial queue to prevent blocking the main thread.
    private(set) var outputQueue = DispatchQueue(label: "BarcodeReaderSheet-outputQueue")
    
    /// Returns the the result of an `AVCaptureSession` setup operation.
    internal var setupResult: SessionSetupResult = .success
    
    /// An object that represents a hardware or virtual capture device like a camera or microphone.
    internal var captureDevice: AVCaptureDevice?
    
    /// Returns the  object that provides media input from a capture device to a capture session.
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    /// A capture output that records video and provides access to video frames for processing.
    private(set) var videoOutput = AVCaptureVideoDataOutput()
    
    /// Returns the aspect ratio of a video buffer.
    internal var bufferAspectRatio: Double!
    
    /// Returns the user interface orientation value for the current window.
    internal var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    // MARK: - View Controller Lifecycle
    
    /// Create a new instance of `BarcodeScannerView` with the specified title.
    /// - Parameters:
    ///   - title: The title to display on the top part of the `UISheetPresentationController`
    ///   - statusMessages: An array of `BarcodeReaderStatus` objects that represents the messages to be displayed in the status label.
    ///   - resultManager:The delegate object responsible for managing user interactions and providing content for the bottom sheet. This object must
    ///   adopt the `BarcodeReaderDelegate`  protocol.
    ///   - symbologies: An array of `VNBarcodeSymbology` objects that represents the barcode symbologies to be recognized.
    public init(
        title: String,
        statusMessages: BarcodeReaderStatus,
        resultManager: BarcodeReaderDelegate,
        symbologies: [VNBarcodeSymbology]
    ) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = self
        self.sheetTitle = title
        self.titleColor = .black
        self.baseBackgroundColor = .white
        self.statusMessages = statusMessages
        self.resultManager = resultManager
        self.barcodeProcessor = BarcodeProcessor(previewView: previewView)
        self.barcodeProcessor.configureSymbologies(to: symbologies)
    }
    
    /// Create a new instance of `BarcodeScannerView` with the nib file in the specified bundle.
    /// - Parameters:
    ///   - nibNameOrNil: The name of the nib file to associate with the view controller.
    ///   - nibBundleOrNil: The bundle in which to search for the nib file.
    private override init(
        nibName nibNameOrNil: String?,
        bundle nibBundleOrNil: Bundle?
    ) {
        super.init(nibName: nil, bundle: nil)
    }
    
    /// Creates a new instance of `BarcodeScannerView` with data in an unarchiver.
    /// - Parameter coder: An unarchiver object.
    required public init?(coder: NSCoder) {
        fatalError("BarcodeScannerView: init(coder:) has not been implemented.")
    }
    
    /// Called when an instance of `InkBarcodeScannerViewController` gets deallocated from memory.
    deinit {
        resultManager = nil
        print("An instance of InkBarcodeScannerViewController has been deallocated from memory.")
    }
    
    /// Called after the controller’s view is loaded into memory.
    public override func viewDidLoad() {
        super.viewDidLoad()
#if targetEnvironment(simulator)
        print("BARCODE READER SHEET LOGS: Error: Camera is not available while using the simulator.")
#else
        startScanning()
#endif
    }
    
    /// Notifies the view controller that its view is about to be added to a view hierarchy.
    /// - Parameter animated: If `true`, the view is being added to the window using an animation.
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if targetEnvironment(simulator)
        print("BARCODE READER SHEET LOGS: Error: Camera is not available while using the simulator.")
        addChildrenViews(unsupportedDeviceLabel)
#endif
    }
    
    /// Notifies the view controller that its view was added to a view hierarchy.
    /// - Parameter animated: If `true`, the view was added to the window using an animation.
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if targetEnvironment(simulator)
        print("BARCODE READER SHEET LOGS: Error: Camera is not available while using the simulator.")
#else
        layoutUIAccesories()
#endif
        resultManager?.executeWhenViewHasAppeared()
    }
    
    /// Notifies the view controller that its view is about to be removed from a view hierarchy.
    /// - Parameter animated: If `true`, the disappearance of the view is being animated.
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    /// Notifies the view controller that its view was removed from a view hierarchy.
    /// - Parameter animated: If `true`, the disappearance of the view was animated.
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
#if targetEnvironment(simulator)
        print("BARCODE READER SHEET LOGS: Error: Camera is not available while using the simulator.")
#else
        stopScanning()
#endif
        resultManager?.executeWhenViewHasDisappeared()
    }
    
    /// Notifies the container that the size of its view is about to change.
    /// - Parameters:
    ///   - size: The new size for the container’s view.
    ///   - coordinator: The transition coordinator object managing the size change. You can use this object to animate your changes or get information
    ///   about the transition that is in progress.
    public override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
#if targetEnvironment(simulator)
        print("BARCODE READER SHEET LOGS: Error: Camera is not available while using the simulator.")
#else
        configurePreviewLayer()
#endif
    }
    
    /// Returns the interface orientations that the view controller supports.
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    /// Configures and starts the starting the scanning process on a camera view.
    ///
    /// It calls several other functions to configure the preview view, status label, and status timer, add children views, and start the camera session.
    private func startScanning() {
        configureSelectedOrientation()
        configurePreviewView()
        configureStatusLabel()
        configureStatusTimer()
        addChildrenViews(previewView)
        startSession()
    }
    
    /// Stops the scanning process on a camera view.
    ///
    /// It calls several other functions to invalidate the status timer, stop the camera session, and turn off the torch if it is on.
    private func stopScanning() {
        invalidateStatusTimer()
        stopSession()
        turnOffTorch()
    }
    
    /// Configures the layout of several UI accessories for a camera view.
    ///
    /// It calls several other functions to configure various UI elements, including the torch button, settings button, barcode orientation view, barcode orientation
    /// stack view, automatic laser view, portrait laser view, landscape laser view, and laser view.
    private func layoutUIAccesories() {
        configureTorchButton()
        configureSettingsButton()
        configureBarcodeOrientationView()
        configureBarcodeOrientationStackView()
        configureAutomaticLaserView()
        configurePortraitLaserView()
        configureLandscapeLaserView()
        configureLaserView()
    }
    
    /// Configures barcodeReader's selectedOrientation property.
    private func configureSelectedOrientation() {
        guard let value = UserDefaults.standard.value(
            forKey: BarcodeReaderSheetIdentifiers.scannerOrientationPreferenceKey
        ) as? String else {
            UserDefaults.standard.set(
                BarcodeReaderSheetIdentifiers.automaticOrientationPreferenceValue,
                forKey: BarcodeReaderSheetIdentifiers.scannerOrientationPreferenceKey
            )
            barcodeProcessor.selectedOrientation = .automatic
            return
        }
        switch value {
        case BarcodeReaderSheetIdentifiers.automaticOrientationPreferenceValue:
            barcodeProcessor.selectedOrientation = .automatic
        case BarcodeReaderSheetIdentifiers.portraitOrientationPreferenceValue:
            barcodeProcessor.selectedOrientation = .portrait
        case BarcodeReaderSheetIdentifiers.landscapeOrientationPreferenceValue:
            barcodeProcessor.selectedOrientation = .landscape
        default:
            barcodeProcessor.selectedOrientation = .automatic
        }
    }
    
}
