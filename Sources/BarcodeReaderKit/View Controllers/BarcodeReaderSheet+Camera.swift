//
//  BarcodeReaderSheet+Camera.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-18.
//

import AVFoundation
import UIKit
import UIKitExtensions

@available(iOS 15.0, *)
extension BarcodeReaderSheet {
    
    /// Represents the result of an `AVCaptureSession` setup operation.
    enum SessionSetupResult {
        
        /// Indicates that the `AVCaptureSession` setup operation was successful.
        case success
        
        /// Indicates that the user has not granted the necessary authorization for the `AVCaptureSession`.
        case notAuthorized
        
        /// Indicates that the configuration of the `AVCaptureSession` has failed.
        case configurationFailed
    }
    
    /// Configures the `previewView` object and the capture session as well.
    ///
    /// Code explanation:
    /// 1) Configure the session and video preview layer properties of the` previewView` object used to display video.
    /// 2) Check the authorization status of the camera.
    /// - If the user has previously authorized access to the camera, the function does nothing.
    /// - If the user has not been presented with the option to grant access to the camera, the function suspends the session queue and requests access.  Once
    /// access is granted or denied, the session queue is resumed.
    /// - f the user has previously denied access, the `setupResult` property is set to `.notAuthorized`.
    ///  3) Configures the capture session on the `sessionQueue` to prevent blocking the main queue and keeping the UI responsive.
    func configurePreviewView() {
        /// Set up the video preview view.
        previewView.session = session
        previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        /// Check the video authorization status. Video access is required.
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            /// The user has previously granted access to the camera.
            break
        case .notDetermined:
            /// The user has not yet been presented with the option to grant video access. Suspend the session queue to delay session  setup until the access
            /// request has completed.
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            }
        default:
            /// The user has previously denied access.
            setupResult = .notAuthorized
        }
        /// Setup the capture session.
        /// In general, it's not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time. Don't
        /// perform these tasks on the main queue because AVCaptureSession.startRunning() is a blocking call, which can take a long time. Dispatch session
        /// setup to the sessionQueue, so that the main queue isn't blocked, which keeps the UI responsive.
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configureSession()
        }
    }
    
    /// Configures the video preview layer based on the device's current orientation.
    ///
    /// Code explanation:
    /// 1) Check if the preview view's video preview layer connection exists.
    /// 2) Retrieve the current device orientation using `UIDevice.current.orientation`.
    /// 3) Convert the device orientation into a valid `AVCaptureVideoOrientation` using the extension `AVCaptureVideoOrientation(deviceOrientation:)`.
    /// 4) Check if the converted video orientation is valid and if the device orientation is either portrait or landscape.
    /// 5) If the converted video orientation is valid and the device orientation is either portrait or landscape, set the preview layer's video orientation to the new video orientation.
    func configurePreviewLayer() {
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
                  deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                return
            }
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }
    
    /// Configures the `AVCaptureSession` object used to capture video input for the barcode reader.
    ///
    /// Code explanation:
    /// 1) Check the `setupResult` to ensure that the barcode reader was successfully set up. If not, print an error message and exit the function.
    /// 2) Begin session configuration.
    /// 3) Choose the video input device based on the available options. This function prefers to use the back dual camera for the video input, but will default to
    /// other available cameras if the dual camera is not available.
    /// 4) Check that a video capture device exists. If not, print an error message, set the `setupResult` to `.configurationFailed` and exit the function.
    /// 5) Set the session preset based on the supported options of the video capture device. A 4k buffer size is used if available to allow recognition of smaller
    /// text, but a smaller buffer size is used otherwise to reduce battery usage.
    /// 6) Create a video device input and add it to the capture session.
    /// 7) Set the video preview layer to display the video stream on the main queue, and set the initial video orientation based on the window scene's orientation.
    /// 8) Add the video output to the session, configure it, and set the sample buffer delegate to the session queue.
    /// 9) Commit the session configuration.
    private func configureSession() {
        guard setupResult == .success else {
            print("BARCODE READER SHEET LOGS: Failed to configure capture session.")
            return
        }
        session.beginConfiguration()
        /// Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            /// Choose the back dual camera, if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                /// If a rear dual camera is not available, default to the rear dual wide camera.
                defaultVideoDevice = dualWideCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                /// If a rear dual wide camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else {
                /// If a rear wide angle camera  is not available, return the default video capture device.
                defaultVideoDevice = AVCaptureDevice.default(for: .video)
            }
            captureDevice = defaultVideoDevice
            /// Check that video capture device exists.
            guard let videoDevice = defaultVideoDevice else {
                print("BARCODE READER SHEET LOGS: Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            /// Configure the currently active minimum frame duration to 30 fps.
//            videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
            /// NOTE:  Requesting 4k buffers allows recognition of smaller text but will consume more power. Use the smallest buffer size necessary to keep down battery usage.
//            if videoDevice.supportsSessionPreset(.hd4K3840x2160) {
//                session.sessionPreset = .hd4K3840x2160
//                bufferAspectRatio = 3840.0 / 2160.0
//            } else
            if videoDevice.supportsSessionPreset(.hd1920x1080) {
                session.sessionPreset = .hd1920x1080
                bufferAspectRatio = 1920.0 / 1080.0
            } else {
                session.sessionPreset = .hd1280x720
                bufferAspectRatio = 1228.0 / 720.0
            }
            /// Create video device input.
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            /// Add video device input to the capture session.
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                DispatchQueue.main.async {
                    /// Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView. You can
                    /// manipulate UIView only on the main thread.
                    /// Note: As an exception to the above rule, it's not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s
                    /// connection with other session manipulation.
                    /// Use the window scene's orientation as the initial video orientation. Subsequent orientation changes are handled by BarcodeReaderSheet.viewWillTransition(to:with:).
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if self.windowOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: self.windowOrientation) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("BARCODE READER SHEET LOGS: Could not add device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch let error {
            print("BARCODE READER SHEET LOGS: Could not create video device input. Error: \(error.localizedDescription)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        /// Add the video output.
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            /// Configure video output
            videoOutput.automaticallyConfiguresOutputBufferDimensions = true
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
            videoOutput.connection(with: AVMediaType.video)?.preferredVideoStabilizationMode = .auto
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            ]
        } else {
            print("BARCODE READER SHEET LOGS: Could not add video output to the session.")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        session.commitConfiguration()
    }
    
    /// Checks the current value of the  `setupResult` property and starts the capture session and the flow of data through the capture pipeline if the
    /// configuration is successful. Otherwise, prompts an alert.
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            switch self.setupResult {
            case .success:
                /// Only setup observers and start the session if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                self.barcodeProcessor.status = .ready
            case .notAuthorized:
                /// Present alert to the user informing them that video access is required with a button that redirects them to settings.
                DispatchQueue.main.async {
                    let alertController = UIAlertController(
                        title: self.defaultErrorMessageTitle,
                        message: self.cameraAuthorisationErrorMessage,
                        preferredStyle: .alert
                    )
                    alertController.addAction(
                        UIAlertAction(
                            title: self.defaultOKButtonTitle,
                            style: .cancel,
                            handler: nil
                        )
                    )
                    alertController.addAction(
                        UIAlertAction(
                            title: self.defaultSettingsButtonTitle,
                            style: .default,
                            handler: { _ in
                                let settingsURL = URL(string: UIApplication.openSettingsURLString)!
                                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                            }
                        )
                    )
                    self.present(alertController, animated: true, completion: nil)
                }
            case .configurationFailed:
                /// Present alert to the user informing them that something went wrong during capture session configuration
                DispatchQueue.main.async {
                    let alertController = UIAlertController(
                        title: self.defaultErrorMessageTitle,
                        message: self.configurationErrorMessage,
                        preferredStyle: .alert
                    )
                    alertController.addAction(
                        UIAlertAction(
                            title: self.defaultOKButtonTitle,
                            style: .cancel,
                            handler: nil
                        )
                    )
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    /// Stops the capture session and the flow of data through the capture pipeline.
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.stopRunning()
        }
    }
    
    /// Configures the focus, exposure, and monitor options for the camera device.
    ///
    /// This function sets the focus and exposure mode for the camera device and specifies a point on the device where the focus and exposure should be
    /// adjusted. The `monitorSubjectAreaChange` parameter indicates whether the device should continuously monitor changes to the subject area.
    /// The function is performed asynchronously on the session queue to prevent blocking of the main thread.
    /// - Parameters:
    ///   - focusMode: An `AVCaptureDevice.FocusMode` value used  to specify the focus mode of a capture device.
    ///   - exposureMode: An `AVCaptureDevice.ExposureMode` value used  to specify the exposure mode of a capture device.
    ///   - devicePoint: The point on the device to focus/expose on.
    ///   - monitorSubjectAreaChange:  A `Bool` value that indicates whether the device should monitor changes to the subject area.
    func setFocus(
        with focusMode: AVCaptureDevice.FocusMode,
        exposureMode: AVCaptureDevice.ExposureMode,
        at devicePoint: CGPoint,
        monitorSubjectAreaChange: Bool
    ) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                if (device.isAutoFocusRangeRestrictionSupported) {
                    device.autoFocusRangeRestriction = .near
                }
                if (device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance)) {
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                }
                /// Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.  Call set(Focus/Exposure)Mode() to apply
                /// the new point of interest.
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch let error {
                print("BARCODE READER SHEET LOGS: Could not lock device for configuration. Error: \(error.localizedDescription)")
            }
        }
    }
    
}
