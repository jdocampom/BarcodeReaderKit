//
//  AVCaptureDevice+Ext.swift
//  BarcodeReader+Ext
//
//  Created by Juan Diego Ocampo on 2023-02-18.
//

import AVFoundation

extension AVCaptureDevice.DiscoverySession {
    
    ///Rreturns the count of unique device positions found in the session's devices.
    ///
    /// The `uniqueDevicePositionsCount` property returns the count of unique device positions found in the session's devices. The position of a
    /// device is specified using the `AVCaptureDevice.Position` enumeration, which can take on one of two values: `.front` or `.back`.
    var uniqueDevicePositionsCount: Int {
        var uniqueDevicePositions = [AVCaptureDevice.Position]()
        for device in devices where !uniqueDevicePositions.contains(device.position) {
            uniqueDevicePositions.append(device.position)
        }
        return uniqueDevicePositions.count
    }
    
}
