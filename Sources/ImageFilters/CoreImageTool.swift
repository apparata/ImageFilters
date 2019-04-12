//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation
import CoreImage

#if canImport(UIKit)
import UIKit
import GLKit
#endif

#if !(targetEnvironment(simulator))
// Can't even compile with Metal on simulator.
import Metal
import MetalKit
#endif

public class CoreImageTool {
    
    internal let ciContext: CIContext
    
    public init() {
        ciContext = CIContext()
    }
    
    public init(options: [CIContextOption: Any] = [:]) {
        ciContext = CIContext(options: options)
    }
    
    internal init(ciContext: CIContext) {
        self.ciContext = ciContext
    }

    #if canImport(UIKit)
    public static func apply(filter filterName: String, image: UIImage, parameters: [String: AnyObject] = [:]) -> CIImage? {
        guard let ciImage = CIImage(image: image) else {
            return nil
        }
        return apply(filter: filterName, image: ciImage, parameters: parameters)
    }
    #endif

    public static func apply(filter filterName: String, image: CIImage, parameters: [String: AnyObject] = [:]) -> CIImage? {
        guard let filter = CIFilter(name: filterName) else {
            return nil
        }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        
        for (key, value) in parameters {
            filter.setValue(value, forKey: key)
        }
        
        let outputImage = filter.outputImage
        return outputImage
    }
    
    #if canImport(UIKit)
    public func renderImage(image: CIImage, deviceScale: CGFloat = 1.0, extent: CGRect? = nil) -> UIImage? {
        let imageExtent = extent ?? image.extent
        guard let renderedImage = ciContext.createCGImage(image, from: imageExtent) else {
            return nil
        }
        let outputImage = UIImage(cgImage: renderedImage, scale: deviceScale, orientation: .up)
        return outputImage
    }
    #endif
}

#if canImport(UIKit)
public final class CoreImageToolOpenGL: CoreImageTool {
    
    private override init() {
        super.init()
    }
    
    public init(glContext: EAGLContext) {
        super.init(ciContext: CIContext(eaglContext: glContext))
    }
    
    public func drawImage(image: CIImage, inView view: GLKView) {
        view.bindDrawable()
        let bounds = CGRect(x: 0.0, y: 0.0, width: Double(view.drawableWidth), height: Double(view.drawableHeight))
        ciContext.draw(image, in: bounds, from: image.extent)
        view.display()
    }
}
#endif

#if !(targetEnvironment(simulator))

@available(iOS 10.0, macOS 10.11, *)
public final class CoreImageToolMetal: CoreImageTool {

    private let colorSpace: CGColorSpace? = CGColorSpaceCreateDeviceRGB()
    
    private override init() {
        super.init()
    }

    public init(device: MTLDevice) {
        super.init(ciContext: CIContext(mtlDevice: device))
    }
    
    /// The MetalKit view must have `framebufferOnly` set to `false`.
    public func drawImage(image: CIImage, inView view: MTKView, commandQueue: MTLCommandQueue) {
        guard let colorSpace = colorSpace else {
            return
        }
        if let drawable = view.currentDrawable {
            let outputTexture = drawable.texture
            let commandBuffer = commandQueue.makeCommandBuffer()
            ciContext.render(image, to: outputTexture, commandBuffer: commandBuffer, bounds: image.extent, colorSpace: colorSpace)
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
    }
}

#endif
