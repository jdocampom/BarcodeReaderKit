//
//  BarcodeReaderCornerView.swift
//  BarcodeReaderKit
//
//  Created by Juan Diego Ocampo on 2023-01-26.
//

import CoreGraphics
import UIKit

@IBDesignable
final class BarcodeReaderCornerView: UIView {
    
    /// Determines the size of the corners of a rectangular view. Defaults to `0.2`.
    @IBInspectable var sizeMultiplier: CGFloat = 0.2 {
        didSet {
            self.draw(self.bounds)
        }
    }
    
    /// Determines the width of the lines used to draw the corners of a rectangular view. Defaults to `2`.
    @IBInspectable var lineWidth: CGFloat = BarcodeReaderConstants.laserViewWidth {
        didSet {
            self.draw(self.bounds)
        }
    }
    
    /// Determines the color of the lines used to draw the corners of a rectangular view. Defaults to `.systemRed`.
    @IBInspectable var lineColor: UIColor = .systemRed {
        didSet {
            self.draw(self.bounds)
        }
    }
    
    /// Creates a view with the specified frame rectangle.
    /// - Parameter frame: The frame rectangle for the view, measured in points. The origin of the frame is relative to the superview in which you plan to add it.
    /// This method uses the frame rectangle to set the center and bounds properties accordingly.
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    /// Creates a view from data in an unarchiver.
    /// - Parameter aDecoder: An unarchiver object.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = .clear
    }
    
    /// Draws the four corners of a rectangular view with a specified line width and color.
    ///
    /// The corners are drawn using the current graphics context, which is obtained using the `UIGraphicsGetCurrentContext()` function.
    private func drawCorners() {
        let currentContext = UIGraphicsGetCurrentContext()
        currentContext?.setLineWidth(lineWidth)
        currentContext?.setStrokeColor(lineColor.cgColor)
        /// First part of top-left corner
        currentContext?.beginPath()
        currentContext?.move(to: CGPoint(x: 0, y: 0))
        currentContext?.addLine(
            to: CGPoint(
                x: self.bounds.size.width * sizeMultiplier,
                y: 0
            )
        )
        currentContext?.strokePath()
        /// Top-right corner
        currentContext?.beginPath()
        currentContext?.move(
            to: CGPoint(
                x: self.bounds.size.width - self.bounds.size.width * sizeMultiplier,
                y: 0
            )
        )
        currentContext?.addLine(
            to: CGPoint(
                x: self.bounds.size.width,
                y: 0
            )
        )
        currentContext?.addLine(
            to: CGPoint(
                x: self.bounds.size.width,
                y: self.bounds.size.height * sizeMultiplier
            )
        )
        currentContext?.strokePath()
        /// Bottom-right corner
        currentContext?.beginPath()
        currentContext?.move(
            to: CGPoint(
                x: self.bounds.size.width,
                y: self.bounds.size.height - self.bounds.size.height * sizeMultiplier
            )
        )
        currentContext?.addLine(
            to: CGPoint(
                x: self.bounds.size.width,
                y: self.bounds.size.height)
        )
        currentContext?.addLine(
            to: CGPoint(
                x: self.bounds.size.width - self.bounds.size.width * sizeMultiplier, y: self.bounds.size.height
            )
        )
        currentContext?.strokePath()
        // Bottom left-corner
        currentContext?.beginPath()
        currentContext?.move(
            to: CGPoint(
                x: self.bounds.size.width * sizeMultiplier,
                y: self.bounds.size.height
            )
        )
        currentContext?.addLine(
            to: CGPoint(
                x: 0,
                y: self.bounds.size.height
            )
        )
        currentContext?.addLine(
            to: CGPoint(
                x: 0,
                y: self.bounds.size.height - self.bounds.size.height * sizeMultiplier
            )
        )
        currentContext?.strokePath()
        /// Second part of top left corner
        currentContext?.beginPath()
        currentContext?.move(
            to: CGPoint(
                x: 0,
                y: self.bounds.size.height * sizeMultiplier
            )
        )
        currentContext?.addLine(
            to: CGPoint(
                x: 0,
                y: 0)
        )
        currentContext?.strokePath()
    }
    
    /// Draws the receiver’s image within the passed-in rectangle.
    /// - Parameter rect: The portion of the view’s bounds that needs to be updated. The first time your view is drawn, this rectangle is typically the entire
    /// visible bounds of your view. However, during subsequent drawing operations, the rectangle may specify only part of your view.
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.drawCorners()
    }
    
}
