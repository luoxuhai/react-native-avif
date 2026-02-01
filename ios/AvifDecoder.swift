//
//  AvifDecoder.swift
//  react-native-avif
//
//  AVIF decoder implementation using Apple's ImageIO framework (iOS 16+)
//  Uses on-demand decoding for better performance
//

import Foundation
import ImageIO
import UIKit

/// Metadata about the AVIF image
@objc public class AvifMetadata: NSObject {
  @objc public let width: Int
  @objc public let height: Int
  @objc public let frameCount: Int
  @objc public let totalDuration: TimeInterval
  @objc public let frameDurations: [NSNumber]

  @objc public init(
    width: Int, height: Int, frameCount: Int, totalDuration: TimeInterval,
    frameDurations: [NSNumber]
  ) {
    self.width = width
    self.height = height
    self.frameCount = frameCount
    self.totalDuration = totalDuration
    self.frameDurations = frameDurations
    super.init()
  }
}

/// AVIF decoder class with on-demand frame decoding
@objc public class AvifDecoder: NSObject {
  private var imageSource: CGImageSource?
  private var imageData: Data?

  @objc public private(set) var metadata: AvifMetadata?
  @objc public private(set) var error: NSError?

  @objc public init?(data: Data) {
    super.init()

    guard !data.isEmpty else {
      self.error = NSError(
        domain: "AvifDecoder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty data"])
      return
    }

    self.imageData = data

    let options = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithData(data as CFData, options) else {
      self.error = NSError(
        domain: "AvifDecoder", code: -2,
        userInfo: [NSLocalizedDescriptionKey: "Failed to create image source"])
      return
    }

    self.imageSource = source

    let frameCount = CGImageSourceGetCount(source)
    guard frameCount > 0 else {
      self.imageSource = nil
      self.error = NSError(
        domain: "AvifDecoder", code: -3,
        userInfo: [NSLocalizedDescriptionKey: "No frames found in AVIF"])
      return
    }

    // Get dimensions from first frame
    guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
    else {
      self.error = NSError(
        domain: "AvifDecoder", code: -4,
        userInfo: [NSLocalizedDescriptionKey: "Failed to get image properties"])
      return
    }

    let width = (properties[kCGImagePropertyPixelWidth as String] as? Int) ?? 0
    let height = (properties[kCGImagePropertyPixelHeight as String] as? Int) ?? 0

    // Collect frame durations
    var durations: [NSNumber] = []
    var totalDuration: TimeInterval = 0

    for i in 0..<frameCount {
      let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any]
      let duration = Self.getFrameDuration(from: frameProperties)
      durations.append(NSNumber(value: duration))
      totalDuration += duration
    }

    self.metadata = AvifMetadata(
      width: width,
      height: height,
      frameCount: frameCount,
      totalDuration: totalDuration,
      frameDurations: durations
    )
  }

  @objc public func decodeFrame(at index: Int) -> UIImage? {
    guard let source = imageSource, let metadata = metadata else {
      return nil
    }

    guard index >= 0 && index < metadata.frameCount else {
      return nil
    }

    let options: [CFString: Any] = [
      kCGImageSourceShouldCacheImmediately: false,
      kCGImageSourceShouldCache: false,
    ]
    guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, options as CFDictionary) else {
      return nil
    }

    return UIImage(cgImage: cgImage)
  }

  @objc public func frameDuration(at index: Int) -> TimeInterval {
    guard let metadata = metadata,
      index >= 0 && index < metadata.frameDurations.count
    else {
      return 0.1
    }
    return metadata.frameDurations[index].doubleValue
  }

  @objc public static func loadMetadata(
    from data: Data, completion: @escaping (AvifDecoder?, AvifMetadata?, NSError?) -> Void
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      let decoder = AvifDecoder(data: data)
      DispatchQueue.main.async {
        if let error = decoder?.error {
          completion(nil, nil, error)
        } else {
          completion(decoder, decoder?.metadata, nil)
        }
      }
    }
  }

  private static func getFrameDuration(from properties: [String: Any]?) -> TimeInterval {
    guard let properties = properties else {
      return 0.1
    }

    // Try HEICS properties (AVIF/HEIF Image Sequence)
    if let heicsProperties = properties[kCGImagePropertyHEICSDictionary as String] as? [String: Any]
    {
      if let delayTime = heicsProperties[kCGImagePropertyHEICSDelayTime as String] as? Double,
        delayTime > 0
      {
        return delayTime
      }
      if let unclampedDelayTime = heicsProperties[kCGImagePropertyHEICSUnclampedDelayTime as String]
        as? Double, unclampedDelayTime > 0
      {
        return unclampedDelayTime
      }
    }

    // Try GIF properties
    if let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
      if let unclampedDelayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String]
        as? Double,
        unclampedDelayTime > 0
      {
        return unclampedDelayTime
      }
      if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double,
        delayTime > 0
      {
        return delayTime
      }
    }

    // Try PNG/APNG properties
    if let pngProperties = properties[kCGImagePropertyPNGDictionary as String] as? [String: Any] {
      if let delayTime = pngProperties[kCGImagePropertyAPNGDelayTime as String] as? Double,
        delayTime > 0
      {
        return delayTime
      }
    }

    // Default: ~42ms (24 fps)
    return 1.0 / 24.0
  }
}
