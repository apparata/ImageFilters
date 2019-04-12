//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation
import CoreImage
#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif

public enum CoreImageFilterError: Error {
    case filterError(filterName: String)
    // Some NSColor (macOS) configurations cannot be represented by Core Image
    case colorNotSupported
    case failedToInitializeMetal
}

public final class CoreImageFilter {
    
    public let coreImageTool: CoreImageTool
    public var image: CIImage
    
    public init(ciImage: CIImage, coreImageTool: CoreImageTool) {
        self.coreImageTool = coreImageTool
        image = ciImage
    }
    
    #if canImport(UIKit)
    public convenience init?(image: UIImage, coreImageTool: CoreImageTool) {
        var ciImage = image.ciImage
        if ciImage == nil {
            if let cgImage = image.cgImage {
                ciImage = CIImage(cgImage: cgImage)
            }
        }
        guard let inputCIImage = ciImage else {
            return nil
        }
        self.init(ciImage: inputCIImage, coreImageTool: coreImageTool)
    }
    #endif
    
    #if canImport(UIKit)
    public func render(deviceScale: CGFloat = 1.0, extent: CGRect? = nil) -> UIImage? {
        return coreImageTool.renderImage(image: image, deviceScale: deviceScale, extent: extent)
    }
    #endif
    
    #if canImport(Cocoa)
    public convenience init?(image: NSImage, coreImageTool: CoreImageTool) {
        
        guard let imageData = image.tiffRepresentation else {
            return nil
        }
        
        guard let ciImage = CIImage(data: imageData) else {
            return nil
        }

        self.init(ciImage: ciImage, coreImageTool: coreImageTool)
    }
    #endif
    
    #if canImport(Cocoa)
    public func render(deviceScale: CGFloat = 1.0, extent: CGRect? = nil) -> NSImage? {
        return coreImageTool.renderImage(image: image, extent: extent)
    }
    #endif
    
    fileprivate func apply(filter filterName: String, parameters: [String: AnyObject] = [:]) throws {
        let newImage = CoreImageTool.apply(filter: filterName, image: image, parameters: parameters)
        guard let filteredImage = newImage else {
            throw CoreImageFilterError.filterError(filterName: filterName)
        }
        image = filteredImage
    }
}

extension CoreImageFilter {
    
    // MARK: Blur
    
    public func boxBlur(radius: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputRadius": radius as NSNumber
        ]
        try apply(filter: "CIBoxBlur", parameters: parameters)
        return self
    }
    
    public func discBlur(radius: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputRadius": radius as NSNumber
        ]
        try apply(filter: "CIDiscBlur", parameters: parameters)
        return self
    }
    
    public func gaussianBlur(radius: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputRadius": radius as NSNumber
        ]
        try apply(filter: "CIGaussianBlur", parameters: parameters)
        return self
    }
    
    public func maskedVariableBlur(mask: CIImage, radius: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputMask": mask,
            "inputRadius": radius as NSNumber
        ]
        try apply(filter: "CIMaskedVariableBlur", parameters: parameters)
        return self
    }
    
    public func medianFilter() throws -> CoreImageFilter {
        try apply(filter: "CIMedianFilter")
        return self
    }
    
    public func motionBlur(radius: Float, angle: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputRadius": radius as NSNumber,
            "inputAngle": angle as NSNumber
        ]
        try apply(filter: "CIMotionBlur", parameters: parameters)
        return self
    }
    
    public func noiseReduction(noiseLevel: Float, sharpness: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputNoiseLevel": noiseLevel as NSNumber,
            "inputSharpness": sharpness as NSNumber
        ]
        try apply(filter: "CINoiseReduction", parameters: parameters)
        return self
    }
    
    public func zoomBlur(center: CIVector, amount: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputAmount": amount as NSNumber
        ]
        try apply(filter: "CIZoomBlur", parameters: parameters)
        return self
    }
    
}

extension CoreImageFilter {
    
    // MARK: Color Adjustment
    
    public func colorClamp(minComponents: CIVector, maxComponents: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputMinComponents": minComponents,
            "inputMaxComponents": maxComponents
        ]
        try apply(filter: "CIColorClamp", parameters: parameters)
        return self
    }
    
    public func colorControls(saturation: Float, brightness: Float, contrast: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputSaturation": saturation as NSNumber,
            "inputBrightness": brightness as NSNumber,
            "inputContrast": contrast as NSNumber
        ]
        try apply(filter: "CIColorControls", parameters: parameters)
        return self
    }
    
    public func colorMatrix(red: CIVector, green: CIVector, blue: CIVector, alpha: CIVector, bias: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputRVector": red,
            "inputGVector": green,
            "inputBVector": blue,
            "inputAVector": alpha,
            "inputBiasVector": bias
        ]
        try apply(filter: "CIColorMatrix", parameters: parameters)
        return self
    }
    
    public func colorPolynomial(redCoefficients: CIVector, greenCoefficients: CIVector, blueCoefficients: CIVector, alphaCoefficients: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputRedCoefficients": redCoefficients,
            "inputGreenCoefficients": greenCoefficients,
            "inputBlueCoefficients": blueCoefficients,
            "inputAlphaCoefficients": alphaCoefficients
        ]
        try apply(filter: "CIColorPolynomial", parameters: parameters)
        return self
    }
    
    public func exposure(ev: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputEV": ev as NSNumber
        ]
        try apply(filter: "CIExposureAdjust", parameters: parameters)
        return self
    }
    
    public func gamma(power: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputPower": power as NSNumber
        ]
        try apply(filter: "CIGammaAdjust", parameters: parameters)
        return self
    }
    
    public func hue(angle: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputAngle": angle as NSNumber
        ]
        try apply(filter: "CIHueAdjust", parameters: parameters)
        return self
    }
    
    public func linearToSRGBToneCurve() throws -> CoreImageFilter {
        try apply(filter: "CILinearToSRGBToneCurve")
        return self
    }
    
    public func sRGBToneCurveToLinear() throws -> CoreImageFilter {
        try apply(filter: "CISRGBToneCurveToLinear")
        return self
    }
    
    public func temperatureAndTine(neutral: CIVector, targetNeutral: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputNeutral": neutral,
            "inputTargetNeutral": targetNeutral
        ]
        try apply(filter: "CITemperatureAndTint", parameters: parameters)
        return self
    }
    
    public func toneCurve(p0: CIVector, p1: CIVector, p2: CIVector, p3: CIVector, p4: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputPoint0": p0,
            "inputPoint1": p1,
            "inputPoint2": p2,
            "inputPoint3": p3,
            "inputPoint4": p4
        ]
        try apply(filter: "CIToneCurve", parameters: parameters)
        return self
    }
    
    public func vibrance(amount: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputAmount": amount as NSNumber
        ]
        try apply(filter: "CIVibrance", parameters: parameters)
        return self
    }
    
    #if canImport(UIKit)
    public func whitePoint(color: UIColor) throws -> CoreImageFilter {
        return try whitePoint(color: CIColor(color: color))
    }
    #endif

    #if canImport(Cocoa)
    public func whitePoint(color: NSColor) throws -> CoreImageFilter {
        guard let ciColor = CIColor(color: color) else {
            throw CoreImageFilterError.colorNotSupported
        }
        return try whitePoint(color: ciColor)
    }
    #endif
    
    public func whitePoint(color: CIColor) throws -> CoreImageFilter {
        let parameters = [
            "inputColor": color
        ]
        try apply(filter: "CIWhitePointAdjust", parameters: parameters)
        return self
    }

}

extension CoreImageFilter {
    
    // MARK: Color Effect
    
    public func colorCrossPolynomial(redCoefficients: CIVector, greenCoefficients: CIVector, blueCoefficients: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputRedCoefficients": redCoefficients,
            "inputGreenCoefficients": greenCoefficients,
            "inputBlueCoefficients": blueCoefficients
        ]
        try apply(filter: "CIColorCrossPolynomial", parameters: parameters)
        return self
    }
    
    public func colorCube(cubeDimension: Float, cubeData: NSData) throws -> CoreImageFilter {
        let parameters = [
            "inputCubeDimension": cubeDimension as NSNumber,
            "inputCubeData": cubeData
        ]
        try apply(filter: "CIColorCube", parameters: parameters)
        return self
    }
    
    /* FIXME */
    /*
     public func colorCube(cubeDimension cubeDimension: Float, cubeData: NSData, colorSpace: CGColorSpaceRef) throws -> CoreImageFilter {
     let parameters = [
     "inputCubeDimension": cubeDimension,
     "inputCubeData": cubeData,
     "inputColorSpace": colorSpace
     ]
     try apply(filter: "CIColorCubeWithColorSpace", parameters: parameters)
     return self
     }*/
    
    public func colorInvert() throws -> CoreImageFilter {
        try apply(filter: "CIColorInvert")
        return self
    }
    
    public func colorMap(gradientImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputGradientImage": gradientImage
        ]
        try apply(filter: "CIColorMap", parameters: parameters)
        return self
    }
    
    public func posterize(levels: Int) throws -> CoreImageFilter {
        let parameters = [
            "inputLevels": levels as NSNumber
        ]
        try apply(filter: "CIColorPosterize", parameters: parameters)
        return self
    }

    #if canImport(UIKit)
    public func monochrome(color: UIColor, intensity: Float) throws -> CoreImageFilter {
        return try monochrome(color: CIColor(color: color), intensity: intensity)
    }
    #endif

    #if canImport(Cocoa)
    public func monochrome(color: NSColor, intensity: Float) throws -> CoreImageFilter {
        guard let ciColor = CIColor(color: color) else {
            throw CoreImageFilterError.colorNotSupported
        }
        return try monochrome(color: ciColor, intensity: intensity)
    }
    #endif
    
    public func monochrome(color: CIColor, intensity: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputColor": color,
            "inputIntensity": intensity as NSNumber
        ]
        try apply(filter: "CIColorMonochrome", parameters: parameters)
        return self
    }
    
    #if canImport(UIKit)
    public func falseColor(color0: UIColor, color1: UIColor) throws -> CoreImageFilter {
        return try falseColor(color0: CIColor(color: color0), color1: CIColor(color: color1))
    }
    #endif
    
    #if canImport(Cocoa)
    public func falseColor(color0: NSColor, color1: NSColor) throws -> CoreImageFilter {
        guard let ciColor0 = CIColor(color: color0),
            let ciColor1 = CIColor(color: color1) else {
            throw CoreImageFilterError.colorNotSupported
        }
        return try falseColor(color0: ciColor0, color1: ciColor1)
    }
    #endif
    
    public func falseColor(color0: CIColor, color1: CIColor) throws -> CoreImageFilter {
        let parameters = [
            "inputColor0": color0,
            "inputColor1": color1
        ]
        try apply(filter: "CIFalseColor", parameters: parameters)
        return self
    }
    
    public func maskToAlpha() throws -> CoreImageFilter {
        try apply(filter: "CIMaskToAlpha")
        return self
    }
    
    // CIMaximumComponent
    
    public func chrome() throws -> CoreImageFilter {
        try apply(filter: "CIPhotoEffectChrome")
        return self
    }
    
    public func fade() throws -> CoreImageFilter {
        try apply(filter: "CIPhotoEffectFade")
        return self
    }
    
    public func instant() throws -> CoreImageFilter {
        try apply(filter: "CIPhotoEffectInstant")
        return self
    }
    
    public func mono() throws -> CoreImageFilter {
        try apply(filter: "CIPhotoEffectMono")
        return self
    }
    public func noir() throws -> CoreImageFilter {
        try apply(filter: "CIPhotoEffectNoir")
        return self
    }
    public func process() throws -> CoreImageFilter {
        try apply(filter: "CIPhotoEffectProcess")
        return self
    }
    
    public func tonal() throws -> CoreImageFilter {
        try apply(filter: "CIPhotoEffectTonal")
        return self
    }
    
    public func transfer() throws -> CoreImageFilter {
        try apply(filter: "CIPhotoEffectTransfer")
        return self
    }
    
    public func sepiaTone(intensity: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputIntensity": intensity as NSNumber
        ]
        try apply(filter: "CISepiaTone", parameters: parameters)
        return self
    }
    
    public func vignette(radius: Float, intensity: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputRadius": radius as NSNumber,
            "inputIntensity": intensity as NSNumber
        ]
        try apply(filter: "CIVignette", parameters: parameters)
        return self
    }
    
    // CIVignetteEffect
    public func vignetteEffect(radius: Float, intensity: Float, center: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputRadius": radius as NSNumber,
            "inputIntensity": intensity as NSNumber
        ]
        try apply(filter: "CIVignetteEffect", parameters: parameters)
        return self
    }
    
}

extension CoreImageFilter {
    
    // MARK: Composite Operation
    
    public func additionCompositing(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIAdditionCompositing", parameters: parameters)
        return self
    }
    
    public func colorBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIColorBlendMode", parameters: parameters)
        return self
    }
    
    public func colorBurnBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIColorBurnBlendMode", parameters: parameters)
        return self
    }
    
    public func colorDodgeBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIColorDodgeBlendMode", parameters: parameters)
        return self
    }
    
    public func darkenBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIDarkenBlendMode", parameters: parameters)
        return self
    }
    
    public func differenceBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIDifferenceBlendMode", parameters: parameters)
        return self
    }
    
    public func divideBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIDivideBlendMode", parameters: parameters)
        return self
    }
    
    public func exclusionBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIExclusionBlendMode", parameters: parameters)
        return self
    }
    
    public func hardLightBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIHardLightBlendMode", parameters: parameters)
        return self
    }
    
    public func hueBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIHueBlendMode", parameters: parameters)
        return self
    }
    
    public func lightenBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CILightenBlendMode", parameters: parameters)
        return self
    }
    
    public func linearBurnBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CILinearBurnBlendMode", parameters: parameters)
        return self
    }
    
    public func linearDodgeBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CILinearDodgeBlendMode", parameters: parameters)
        return self
    }
    
    public func luminosityBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CILuminosityBlendMode", parameters: parameters)
        return self
    }
    
    public func maximumCompositing(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIMaximumCompositing", parameters: parameters)
        return self
    }
    
    public func minimumCompositing(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIMinimumCompositing", parameters: parameters)
        return self
    }
    
    public func multiplyBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIMultiplyBlendMode", parameters: parameters)
        return self
    }
    
    public func multiplyCompositing(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIMultiplyCompositing", parameters: parameters)
        return self
    }
    
    public func overlayBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIOverlayBlendMode", parameters: parameters)
        return self
    }
    
    public func pinLightBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIPinLightBlendMode", parameters: parameters)
        return self
    }
    
    public func saturationBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CISaturationBlendMode", parameters: parameters)
        return self
    }
    
    public func screenBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CIScreenBlendMode", parameters: parameters)
        return self
    }
    
    public func softLightBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CISoftLightBlendMode", parameters: parameters)
        return self
    }
    
    public func sourceAtopCompositing(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CISourceAtopCompositing", parameters: parameters)
        return self
    }
    
    public func sourceInCompositing(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CISourceInCompositing", parameters: parameters)
        return self
    }
    
    public func sourceOutCompositing(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CISourceOutCompositing", parameters: parameters)
        return self
    }
    
    public func sourceOverCompositing(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CISourceOverCompositing", parameters: parameters)
        return self
    }
    
    public func subtractBlendMode(backgroundImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage
        ]
        try apply(filter: "CISubtractBlendMode", parameters: parameters)
        return self
    }
}

extension CoreImageFilter {
    
    // MARK: Distortion Effect
    
    public func CIBumpDistortion(center: CIVector, radius: Float, scale: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputRadius": radius as NSNumber,
            "inputScale": scale as NSNumber
        ]
        try apply(filter: "CIBumpDistortionLinear", parameters: parameters)
        return self
    }
    
    public func CIBumpDistortionLinear(center: CIVector, radius: Float, angle: Float, scale: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputRadius": radius as NSNumber,
            "inputAngle": angle as NSNumber,
            "inputScale": scale as NSNumber
        ]
        try apply(filter: "CIBumpDistortionLinear", parameters: parameters)
        return self
    }
    
    public func circleSplashDistortion(center: CIVector, radius: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputRadius": radius as NSNumber
        ]
        try apply(filter: "CICircleSplashDistortion", parameters: parameters)
        return self
    }
    
    public func circularWrap(center: CIVector, radius: Float, angle: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputRadius": radius as NSNumber,
            "inputAngle": angle as NSNumber
        ]
        try apply(filter: "CICircularWrap", parameters: parameters)
        return self
    }
    
    public func droste(insetPoint0: CIVector, insetPoint1: CIVector, strands: Float, periodicity: Float, rotation: Float, zoom: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputInsetPoint0": insetPoint0,
            "inputInsetPoint1": insetPoint0,
            "inputStrands": strands as NSNumber,
            "inputPeriodicity": periodicity as NSNumber,
            "inputRotation": rotation as NSNumber,
            "inputZoom": zoom as NSNumber
        ]
        try apply(filter: "CIDroste", parameters: parameters)
        return self
    }
    
    public func displacementDistortion(displacementImage: CIImage, scale: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputDisplacementDistortion": displacementImage,
            "inputScale": scale as NSNumber
        ]
        try apply(filter: "CIDisplacementDistortion", parameters: parameters)
        return self
    }
    
    public func glassDistortion(texture: CIImage, center: CIVector, scale: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputTexture": texture,
            "inputCenter": center,
            "inputScale": scale as NSNumber
        ]
        try apply(filter: "CIGlassDistortion", parameters: parameters)
        return self
    }
    
    public func torusLensDistortion(point0: CIVector, point1: CIVector, radius: Float, refraction: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputPoint0": point0,
            "inputPoint1": point1,
            "inputRadius": radius as NSNumber,
            "inputRefraction": refraction as NSNumber
        ]
        try apply(filter: "CITorusLensDistortion", parameters: parameters)
        return self
    }
    
    public func holeDistortion(center: CIVector, radius: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputRadius": radius as NSNumber
        ]
        try apply(filter: "CIHoleDistortion", parameters: parameters)
        return self
    }
    
    public func lightTunnel(center: CIVector, radius: Float, rotation: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputRadius": radius as NSNumber,
            "inputRotation": rotation as NSNumber
        ]
        try apply(filter: "CILightTunnel", parameters: parameters)
        return self
    }
    
    public func pinchDistortion(center: CIVector, radius: Float, scale: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputRadius": radius as NSNumber,
            "inputScale": scale as NSNumber
        ]
        try apply(filter: "CIPinchDistortion", parameters: parameters)
        return self
    }
    
    public func torusLensDistortion(center: CIVector, radius: Float, width: Float, refraction: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputRadius": radius as NSNumber,
            "inputAngle": width as NSNumber,
            "inputRefraction": refraction as NSNumber
        ]
        try apply(filter: "CITorusLensDistortion", parameters: parameters)
        return self
    }
    
    public func twirlDistortion(center: CIVector, radius: Float, angle: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputRadius": radius as NSNumber,
            "inputAngle": angle as NSNumber
        ]
        try apply(filter: "CITwirlDistortion", parameters: parameters)
        return self
    }
    
    public func vortexDistortion(center: CIVector, radius: Float, angle: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputRadius": radius as NSNumber,
            "inputAngle": angle as NSNumber
        ]
        try apply(filter: "CIVortexDistortion", parameters: parameters)
        return self
    }
}

extension CoreImageFilter {
    
    // MARK: Generator
    
    //CIAztecCodeGenerator
    //CICheckerboardGenerator
    //CICode128BarcodeGenerator
    //CIConstantColorGenerator
    //CILenticularHaloGenerator
    //CIPDF417BarcodeGenerator
    //CIQRCodeGenerator
    //CIRandomGenerator
    //CIStarShineGenerator
    //CIStripesGenerator
    //CISunbeamsGenerator
    
}

extension CoreImageFilter {
    
    // MARK: Geometry Adjustment
    
    #if canImport(UIKit)
    public func affineTransform(transform: CGAffineTransform) throws -> CoreImageFilter {
        let parameters = [
            "inputTransform": NSValue(cgAffineTransform: transform)
        ]
        try apply(filter: "CIAffineTransform", parameters: parameters)
        return self
    }
    #endif
    
    public func crop(rectangle: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputRectangle": rectangle
        ]
        try apply(filter: "CICrop", parameters: parameters)
        return self
    }
    
    public func lanczosScaleTransform(scale: Float, aspectRatio: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputScale": scale as NSNumber,
            "inputAspectRatio": aspectRatio as NSNumber
        ]
        try apply(filter: "CILanczosScaleTransform", parameters: parameters)
        return self
    }
    
    public func perspectiveTransform(topLeft: CIVector, topRight: CIVector, bottomRight: CIVector, bottomLeft: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputTopLeft": topLeft,
            "inputTopRight": topRight,
            "inputBottomRight": bottomRight,
            "inputBottomLeft": bottomLeft,
            ]
        try apply(filter: "CIPerspectiveTransform", parameters: parameters)
        return self
    }
    
    public func perspectiveTransform(extent: CIVector, topLeft: CIVector, topRight: CIVector, bottomRight: CIVector, bottomLeft: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputExtent": extent,
            "inputTopLeft": topLeft,
            "inputTopRight": topRight,
            "inputBottomRight": bottomRight,
            "inputBottomLeft": bottomLeft,
            ]
        try apply(filter: "CIPerspectiveTransformWithExtent", parameters: parameters)
        return self
    }
    
    public func CIStraightenFilter(angle: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputAngle": angle as NSNumber
        ]
        try apply(filter: "CIStraightenFilter", parameters: parameters)
        return self
    }
}

extension CoreImageFilter {
    
    // MARK: Gradient
    
    //CIGaussianGradient
    //CILinearGradient
    //CIRadialGradient
    //CISmoothLinearGradient
    
    
}

extension CoreImageFilter {
    
    // MARK: Halftone Effect
    
    public func circularScreen(center: CIVector, angle: Float, width: Float, sharpness: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputWidth": width as NSNumber,
            "inputSharpness": sharpness as NSNumber
        ]
        try apply(filter: "CICircularScreen", parameters: parameters)
        return self
    }
    
    public func cmykHalftone(center: CIVector, angle: Float, width: Float, sharpness: Float, gcr: Float, ucr: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputAngle": angle as NSNumber,
            "inputWidth": width as NSNumber,
            "inputSharpness": sharpness as NSNumber,
            "inputGCR": gcr as NSNumber,
            "inputUCR": ucr as NSNumber
        ]
        try apply(filter: "CICMYKHalftone", parameters: parameters)
        return self
    }
    
    public func dotScreen(center: CIVector, angle: Float, width: Float, sharpness: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputAngle": angle as NSNumber,
            "inputWidth": width as NSNumber,
            "inputSharpness": sharpness as NSNumber
        ]
        try apply(filter: "dotScreen", parameters: parameters)
        return self
    }
    
    public func hatchedScreen(center: CIVector, angle: Float, width: Float, sharpness: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputAngle": angle as NSNumber,
            "inputWidth": width as NSNumber,
            "inputSharpness": sharpness as NSNumber
        ]
        try apply(filter: "CIHatchedScreen", parameters: parameters)
        return self
    }
    
    public func lineScreen(center: CIVector, angle: Float, width: Float, sharpness: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputAngle": angle as NSNumber,
            "inputWidth": width as NSNumber,
            "inputSharpness": sharpness as NSNumber
        ]
        try apply(filter: "CILineScreen", parameters: parameters)
        return self
    }
}

extension CoreImageFilter {
    
    // MARK: Reduction
    
    public func areaAverage(extent: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputExtent": extent
        ]
        try apply(filter: "CIAreaAverage", parameters: parameters)
        return self
    }
    
    public func areaHistogram(extent: CIVector, count: Int, scale: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputExtent": extent,
            "inputCount": count as NSNumber,
            "inputScale": scale as NSNumber
        ]
        try apply(filter: "CIAreaHistogram", parameters: parameters)
        return self
    }
    
    public func rowAverage(extent: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputExtent": extent
        ]
        try apply(filter: "CIRowAverage", parameters: parameters)
        return self
    }
    
    public func columnAverage(extent: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputExtent": extent
        ]
        try apply(filter: "CIColumnAverage", parameters: parameters)
        return self
    }
    
    public func histogramDisplayFilter(height: Float, highLimit: Float, lowLimit: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputHeight": height as NSNumber,
            "inputHighLimit": highLimit as NSNumber,
            "inputLowLimit": lowLimit as NSNumber
        ]
        try apply(filter: "CIHistogramDisplayFilter", parameters: parameters)
        return self
    }
    
    public func areaMaximum(extent: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputExtent": extent
        ]
        try apply(filter: "CIAreaMaximum", parameters: parameters)
        return self
    }
    
    public func areaMinimum(extent: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputExtent": extent
        ]
        try apply(filter: "CIAreaMinimum", parameters: parameters)
        return self
    }
    
    public func areaMaximumAlpha(extent: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputExtent": extent
        ]
        try apply(filter: "CIAreaMaximumAlpha", parameters: parameters)
        return self
    }
    
    public func areaMinimumAlpha(extent: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputExtent": extent
        ]
        try apply(filter: "CIAreaMinimumAlpha", parameters: parameters)
        return self
    }
}

extension CoreImageFilter {
    
    // MARK: Sharpen
    
    public func CISharpenLuminance(sharpness: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputSharpness": sharpness as NSNumber
        ]
        try apply(filter: "CISharpenLuminance", parameters: parameters)
        return self
    }
    
    public func unsharpMask(radius: Float, intensity: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputRadius": radius as NSNumber,
            "inputIntensity": intensity as NSNumber
        ]
        try apply(filter: "CIUnsharpMask", parameters: parameters)
        return self
    }
}

extension CoreImageFilter {
    
    // MARK: Stylize
    
    public func blendWithAlphaMask(backgroundImage: CIImage, maskImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage,
            "inputMaskImage": maskImage
        ]
        try apply(filter: "CIBlendWithAlphaMask", parameters: parameters)
        return self
    }
    
    public func blendWithMask(backgroundImage: CIImage, maskImage: CIImage) throws -> CoreImageFilter {
        let parameters = [
            "inputBackgroundImage": backgroundImage,
            "inputMaskImage": maskImage
        ]
        try apply(filter: "CIBlendWithMask", parameters: parameters)
        return self
    }
    
    public func bloom(radius: Float, intensity: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputRadius": radius as NSNumber,
            "inputIntensity": intensity as NSNumber
        ]
        try apply(filter: "CIBloom", parameters: parameters)
        return self
    }
    
    public func comicEffect() throws -> CoreImageFilter {
        try apply(filter: "CIComicEffect")
        return self
    }
    
    public func convolution3x3(weights: CIVector, bias: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputWeights": weights,
            "inputBias": bias as NSNumber
        ]
        try apply(filter: "CIConvolution3X3", parameters: parameters)
        return self
    }
    
    public func convolution5x5(weights: CIVector, bias: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputWeights": weights,
            "inputBias": bias as NSNumber
        ]
        try apply(filter: "CIConvolution5X5", parameters: parameters)
        return self
    }
    
    public func convolution7x7(weights: CIVector, bias: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputWeights": weights,
            "inputBias": bias as NSNumber
        ]
        try apply(filter: "CIConvolution7X7", parameters: parameters)
        return self
    }
    
    public func convolution9Horizontal(weights: CIVector, bias: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputWeights": weights,
            "inputBias": bias as NSNumber
        ]
        try apply(filter: "CIConvolution9Horizontal", parameters: parameters)
        return self
    }
    
    public func convolution9Vertical(weights: CIVector, bias: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputWeights": weights,
            "inputBias": bias as NSNumber
        ]
        try apply(filter: "CIConvolution9Vertical", parameters: parameters)
        return self
    }
    
    public func crystallize(radius: Float, center: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputRadius": radius as NSNumber,
            "inputCenter": center
        ]
        try apply(filter: "CICrystallize", parameters: parameters)
        return self
    }
    
    public func depthOfField(point0: CIVector, point1: CIVector, saturation: Float, unsharpMaskRadius: Float, unsharpMaskIntensity: Float, radius: Float) throws -> CoreImageFilter  {
        let parameters = [
            "inputPoint0": point0,
            "inputPoint1": point1,
            "inputSaturation": saturation as NSNumber,
            "inputUnsharpMaskRadius": unsharpMaskRadius as NSNumber,
            "inputUnsharpMaskIntensity": unsharpMaskIntensity as NSNumber,
            "inputRadius": radius as NSNumber
        ]
        try apply(filter: "CIDepthOfField", parameters: parameters)
        return self
    }
    
    public func edges(intensity: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputIntensity": intensity as NSNumber
        ]
        try apply(filter: "CIEdges", parameters: parameters)
        return self
    }
    
    public func edgeWork(radius: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputRadius": radius as NSNumber
        ]
        try apply(filter: "CIEdgeWork", parameters: parameters)
        return self
    }
    
    public func gloom(radius: Float, intensity: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputRadius": radius as NSNumber,
            "inputIntensity": intensity as NSNumber
        ]
        try apply(filter: "CIGloom", parameters: parameters)
        return self
    }
    
    public func heightFieldFromMask(radius: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputRadius": radius as NSNumber
        ]
        try apply(filter: "CIHeightFieldFromMask", parameters: parameters)
        return self
    }
    
    public func hexagonalPixellate(center: CIVector, scale: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenter": center,
            "inputScale": scale as NSNumber
        ]
        try apply(filter: "hexagonalPixellate", parameters: parameters)
        return self
    }
    
    public func highlightShadowAdjust(highlightAmount: Float, shadowAmount: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputHighlightAmount": highlightAmount as NSNumber,
            "inputShadowAmount": shadowAmount as NSNumber
        ]
        try apply(filter: "CIHighlightShadowAdjust", parameters: parameters)
        return self
    }
    
    public func lineOverlay(nrNoiseLevel: Float, nrSharpness: Float, edgeIntensity: Float, threshold: Float, contrast: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputNRNoiseLevel": nrNoiseLevel as NSNumber,
            "inputNRSharpness": nrSharpness as NSNumber,
            "inputEdgeIntensity": edgeIntensity as NSNumber,
            "inputThreshold": threshold as NSNumber,
            "inputContrast": contrast as NSNumber
        ]
        try apply(filter: "CILineOverlay", parameters: parameters)
        return self
    }
    
    public func pixellate(scale: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputScale": scale as NSNumber
        ]
        try apply(filter: "CIPixellate", parameters: parameters)
        return self
    }
    
    public func pointillize(radius: Float, center: CIVector) throws -> CoreImageFilter {
        let parameters = [
            "inputRadius": radius as NSNumber,
            "inputCenter": center
        ]
        try apply(filter: "CIPointillize", parameters: parameters)
        return self
    }
    
    public func shadedMaterial(shadingImage: CIImage, scale: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputShadingImage": shadingImage,
            "inputScale": scale as NSNumber
        ]
        try apply(filter: "CIShadedMaterial", parameters: parameters)
        return self
    }
    
    #if canImport(UIKit)
    public func spotColor(centerColor1: UIColor, replacementColor1: UIColor, closeness1: Float, contrast1: Float, centerColor2: UIColor, replacementColor2: UIColor, closeness2: Float, contrast2: Float, centerColor3: UIColor, replacementColor3: UIColor, closeness3: Float, contrast3: Float) throws -> CoreImageFilter {
        return try spotColor(centerColor1: CIColor(color: centerColor1),
                             replacementColor1: CIColor(color: replacementColor1),
                             closeness1: closeness1,
                             contrast1: contrast1,
                             centerColor2: CIColor(color: centerColor2),
                             replacementColor2: CIColor(color: replacementColor2),
                             closeness2: closeness2,
                             contrast2: contrast2,
                             centerColor3: CIColor(color: centerColor3),
                             replacementColor3: CIColor(color: replacementColor3),
                             closeness3: closeness3,
                             contrast3: contrast3)
    }
    #endif
    
    #if canImport(Cocoa)
    public func spotColor(centerColor1: NSColor, replacementColor1: NSColor, closeness1: Float, contrast1: Float, centerColor2: NSColor, replacementColor2: NSColor, closeness2: Float, contrast2: Float, centerColor3: NSColor, replacementColor3: NSColor, closeness3: Float, contrast3: Float) throws -> CoreImageFilter {
        
        guard let ciCenterColor1 = CIColor(color: centerColor1),
            let ciReplacementColor1 = CIColor(color: replacementColor1),
            let ciCenterColor2 = CIColor(color: centerColor2),
            let ciReplacementColor2 = CIColor(color: replacementColor2),
            let ciCenterColor3 = CIColor(color: centerColor3),
            let ciReplacementColor3 = CIColor(color: replacementColor3) else {
            throw CoreImageFilterError.colorNotSupported
        }
        
        return try spotColor(centerColor1: ciCenterColor1,
                             replacementColor1: ciReplacementColor1,
                             closeness1: closeness1,
                             contrast1: contrast1,
                             centerColor2: ciCenterColor2,
                             replacementColor2: ciReplacementColor2,
                             closeness2: closeness2,
                             contrast2: contrast2,
                             centerColor3: ciCenterColor3,
                             replacementColor3: ciReplacementColor3,
                             closeness3: closeness3,
                             contrast3: contrast3)
    }
    #endif
    
    public func spotColor(centerColor1: CIColor, replacementColor1: CIColor, closeness1: Float, contrast1: Float, centerColor2: CIColor, replacementColor2: CIColor, closeness2: Float, contrast2: Float, centerColor3: CIColor, replacementColor3: CIColor, closeness3: Float, contrast3: Float) throws -> CoreImageFilter {
        let parameters = [
            "inputCenterColor1": centerColor1,
            "inputReplacementColor1": replacementColor1,
            "inputCloseness1": closeness1 as NSNumber,
            "inputContrast1": contrast1 as NSNumber,
            "inputCenterColor1": centerColor2,
            "inputReplacementColor1": replacementColor2,
            "inputCloseness1": closeness2 as NSNumber,
            "inputContrast1": contrast2 as NSNumber,
            "inputCenterColor1": centerColor3,
            "inputReplacementColor1": replacementColor3,
            "inputCloseness1": closeness3 as NSNumber,
            "inputContrast1": contrast3 as NSNumber
        ]
        try apply(filter: "CISpotColor", parameters: parameters)
        return self
    }
    
    #if canImport(UIKit)
    public func spotlight(lightPosition: CIVector, lightPointsAt: CIVector, brightness: Float, concentration: Float, color: UIColor) throws -> CoreImageFilter {
        return try spotlight(lightPosition: lightPosition, lightPointsAt: lightPointsAt, brightness: brightness, concentration: concentration, color: CIColor(color: color))
    }
    #endif
    
    #if canImport(Cocoa)
    public func spotlight(lightPosition: CIVector, lightPointsAt: CIVector, brightness: Float, concentration: Float, color: NSColor) throws -> CoreImageFilter {
        guard let ciColor = CIColor(color: color) else {
            throw CoreImageFilterError.colorNotSupported
        }
        return try spotlight(lightPosition: lightPosition, lightPointsAt: lightPointsAt, brightness: brightness, concentration: concentration, color: ciColor)
    }
    #endif
    
    public func spotlight(lightPosition: CIVector, lightPointsAt: CIVector, brightness: Float, concentration: Float, color: CIColor) throws -> CoreImageFilter {
        let parameters = [
            "inputLightPosition": lightPosition,
            "inputLightPointsAt": lightPointsAt,
            "inputBrightness": brightness as NSNumber,
            "inputConcentration": concentration as NSNumber,
            "inputColor": color
        ]
        try apply(filter: "CISpotLight", parameters: parameters)
        return self
    }
    
}

extension CoreImageFilter {
    
    // MARK: Tile Effect (TODO)
    
    // CIAffineClamp
    // CIAffineTile
    // CIEightfoldReflectedTile
    // CIFourfoldReflectedTile
    // CIFourfoldRotatedTile
    // CIFourfoldTranslatedTile
    // CIGlideReflectedTile
    // CIKaleidoscope
    // CIOpTile
    // CIParallelogramTile
    // CIPerspectiveTile
    // CISixfoldReflectedTile
    // CISixfoldRotatedTile
    // CITriangleKaleidoscope
    // CITriangleTile
    // CITwelvefoldReflectedTile
    
}

extension CoreImageFilter {
    
    // MARK: Transition (TODO)
    
    // CIAccordionFoldTransition
    // CIBarsSwipeTransition
    // CICopyMachineTransition
    // CIDisintegrateWithMaskTransition
    // CIDissolveTransition
    // CIFlashTransition
    // CIModTransition
    // CIPageCurlTransition
    // CIPageCurlWithShadowTransition
    // CIRippleTransition
    // CISwipeTransition
}
