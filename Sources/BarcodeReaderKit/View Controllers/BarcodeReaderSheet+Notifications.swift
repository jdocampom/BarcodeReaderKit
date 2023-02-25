//
//  BarcodeReaderSheet+Notifications.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-02-18.
//

import AVFoundation
import UIKit
import UIKitExtensions

@available(iOS 15.0, *)
extension BarcodeReaderSheet {
    
    // MARK: - Key-Value Observers and Notifications

    /// Register all observer entries from the application's `NotificationCenter` to monitor and handle interruptions.
    func addObservers() {
        let keyValueObservation = session.observe(\.isRunning, options: .new) { _, change in
//            guard let isSessionRunning = change.newValue else { return }
//            print(isSessionRunning)
        }
        keyValueObservations.append(keyValueObservation)
        let systemPressureStateObservation = observe(\.videoDeviceInput.device.systemPressureState, options: .new) { _, change in
            guard let systemPressureState = change.newValue else { return }
            self.setRecommendedFrameRateRangeForPressureState(systemPressureState: systemPressureState)
        }
        keyValueObservations.append(systemPressureStateObservation)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clientaAppWillResignActive(_:)),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subjectAreaDidChange(_:)),
            name: .AVCaptureDeviceSubjectAreaDidChange,
            object: videoDeviceInput.device
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionRuntimeError(_:)),
            name: .AVCaptureSessionRuntimeError,
            object: session
        )
        /// A session can only run when the app is full screen. It will be interrupted in a multi-app layout, introduced in iOS 9, see also the documentation of
        /// AVCaptureSessionInterruptionReason. Add observers to handle these session interruptions and show a preview is paused message. See the
        /// documentation of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionWasInterrupted(_:)),
            name: .AVCaptureSessionWasInterrupted,
            object: session
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded(_:)),
            name: .AVCaptureSessionInterruptionEnded,
            object: session
        )
    }
    
    /// Removes all observer entries from the application's `NotificationCenter`.
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        keyValueObservations.forEach { $0.invalidate() }
        keyValueObservations.removeAll()
    }
    
    /// Called when the subject area changes on the `AVCaptureSession` in order to restore focus point to the center.
    /// - Parameter notification: A container for information broadcast through a notification center to all registered observers.
    @objc func clientaAppWillResignActive(_ notification: Notification) {
        torchIsOn = false
        turnOffTorch()
    }
    
    /// Called when the subject area changes on the `AVCaptureSession` in order to restore focus point to the center.
    /// - Parameter notification: A container for information broadcast through a notification center to all registered observers.
    @objc func subjectAreaDidChange(_ notification: Notification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        setFocus(
            with: .continuousAutoFocus,
            exposureMode: .continuousAutoExposure,
            at: devicePoint,
            monitorSubjectAreaChange: false
        )
    }

    /// Called when a runtime error occurs in the `AVCaptureSession`.
    /// - Parameter notification: A container for information broadcast through a notification center to all registered observers.
    @objc func sessionRuntimeError(_ notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        print("BARCODE READER SHEET LOGS: Capture session runtime error: \(error.localizedDescription)")
        /// If media services were reset, and the last start succeeded, restart the session.
        if error.code == .mediaServicesWereReset {
            sessionQueue.async { [weak self] in
                guard let self else { return }
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                }
            }
        } else if error.code == .outOfMemory {
            sessionQueue.async { [weak self] in
                guard let self else { return }
                if self.isSessionRunning {
                    self.session.stopRunning()
                    self.isSessionRunning = self.session.isRunning
                }
                self.dismissSheetViewController()
            }
        } else if error.code == .sessionWasInterrupted {
            sessionQueue.async { [weak self] in
                guard let self else { return }
                if self.isSessionRunning {
                    self.session.stopRunning()
                    self.isSessionRunning = self.session.isRunning
                }
            }
        } else if error.code == .sessionNotRunning {
            sessionQueue.async { [weak self] in
                guard let self else { return }
                if !self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                }
            }
        } else {
            sessionQueue.async { [weak self] in
                guard let self else { return }
                if self.isSessionRunning {
                    self.session.stopRunning()
                    self.isSessionRunning = self.session.isRunning
                }
                DispatchQueue.main.async {
                    self.dismissSheetViewController()
                    self.resultManager?.failedToScanBarcode(with: error)
                }
            }
        }
    }
    
    /// Called when an interruption in the `AVCaptureSession` begins.
    /// - Parameter notification: A container for information broadcast through a notification center to all registered observers.
    @objc func sessionWasInterrupted(_ notification: Notification) {
        /// In some scenarios you want to enable the user to resume the session. For example, if music playback is initiated from Control Center while using
        /// AVCam, then the user can let AVCam resume the session running, which will stop music playback. Note that stopping music playback in Control
        /// Center will not automatically resume the session. Also note that it's not always possible to resume, see `resumeInterruptedSession(_:)`.
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
           let reasonIntegerValue = userInfoValue.integerValue,
           let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("BARCODE READER SHEET LOGS: Capture session was interrupted with reason \(reason).")
            if reason == .audioDeviceInUseByAnotherClient || reason == .videoDeviceInUseByAnotherClient {
                print("BARCODE READER SHEET LOGS: Session stopped running due to device being used by another client.")
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                print("BARCODE READER SHEET LOGS: Session stopped running due to device not being available.")
            } else if reason == .videoDeviceNotAvailableDueToSystemPressure {
                print("BARCODE READER SHEET LOGS: Session stopped running due to shutdown system pressure level.")
            }
        }
    }
    
    /// Called when an interruption in the `AVCaptureSession` finishes.
    /// - Parameter notification: A container for information broadcast through a notification center to all registered observers.
    @objc func sessionInterruptionEnded(_ notification: Notification) {
        print("BARCODE READER SHEET LOGS: Capture session interruption ended.")
    }
    
    /// Sets the recommended frame rate range for a given system pressure state to avoid unexpected shutdown of the capture session.
    /// - Parameter systemPressureState: The current system pressure state of the device.
    func setRecommendedFrameRateRangeForPressureState(systemPressureState: AVCaptureDevice.SystemPressureState) {
        /// Get the current system pressure level.
        let pressureLevel = systemPressureState.level
        /// If the pressure level is serious or critical, throttle the frame rate to avoid shutdown.
        if pressureLevel == .serious || pressureLevel == .critical {
            do {
                /// Lock the device for configuration.
                try self.videoDeviceInput.device.lockForConfiguration()
                ///Output a warning message to the console.
                print("BARCODE READER SHEET LOGS: Warning! Reached elevated system pressure level: \(pressureLevel). Throttling frame rate.")
                /// Set the minimum and maximum frame duration to reduce pressure.
                self.videoDeviceInput.device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 20)
                self.videoDeviceInput.device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 15)
                /// Unlock the device.
                self.videoDeviceInput.device.unlockForConfiguration()
            } catch let error {
                /// Output an error message to the console.
                print("BARCODE READER SHEET LOGS: Could not lock device for configuration. Error: \(error.localizedDescription)")
            }
        /// If the pressure level is shutdown, output a message to the console indicating that the session has stopped running
        } else if pressureLevel == .shutdown {
            print("BARCODE READER SHEET LOGS: Session stopped running due to shutdown system pressure level.")
        }
    }
    
}
