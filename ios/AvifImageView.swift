//
//  AvifImageView.swift
//  react-native-avif
//
//  AVIF image view implementation - decodes all frames upfront for smooth playback
//

import Foundation
import UIKit

/// Delegate protocol for handling AVIF image view events
@objc public protocol AvifImageViewDelegate: AnyObject {
  func handleOnLoadStart()
  func handleOnLoad()
  func handleOnLoadEnd()
  func handleOnError(error: String)
}

/// UIImageView subclass for displaying AVIF images with animation support
@objcMembers
public class AvifImageViewCore: UIImageView, URLSessionDownloadDelegate {
  // MARK: - Properties

  public weak var delegate: AvifImageViewDelegate?

  public var source: NSDictionary? {
    didSet {
      handleSourceChange()
    }
  }

  public var loopCount: Int = 0 {
    didSet {
      totalLoopCount = loopCount
    }
  }

  public var resizeMode: String = "contain" {
    didSet {
      updateResizeMode()
    }
  }

  // MARK: - Private Properties

  private var decoder: AvifDecoder?
  private var metadata: AvifMetadata?
  private var currentFrameIndex: Int = 0
  private var displayLink: CADisplayLink?
  private var isAnimated: Bool = false
  private var isPlaying: Bool = false
  private var totalLoopCount: Int = 0
  private var currentLoopCount: Int = 0
  private var frameAccumulator: TimeInterval = 0
  private var lastTimestamp: CFTimeInterval = 0
  private var retryCount: Int = 0
  private var currentURL: URL?

  // On-demand buffering
  private var frameBuffer: [Int: UIImage] = [:]
  private var decodingIndices: Set<Int> = []
  private let bufferWindow = 5

  // High-priority queue for frame decoding
  private let decodeQueue = DispatchQueue(
    label: "com.avif.decode", qos: .userInitiated, attributes: .concurrent)

  private static let maxRetryCount = 3

  // MARK: - Initialization

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  deinit {
    stopAnimation()
  }

  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    if superview == nil {
      clearImage()
    }
  }

  // MARK: - Setup

  private func setup() {
    clipsToBounds = true
    updateResizeMode()
  }

  private func updateResizeMode() {
    switch resizeMode {
    case "cover":
      contentMode = .scaleAspectFill
    case "contain":
      contentMode = .scaleAspectFit
    case "stretch":
      contentMode = .scaleToFill
    case "center":
      contentMode = .center
    default:
      contentMode = .scaleAspectFit
    }
  }

  // MARK: - Source Handling

  private func handleSourceChange() {
    guard let source = source else {
      clearImage()
      return
    }

    guard let uri = source["uri"] as? String, !uri.isEmpty else {
      clearImage()
      return
    }

    // Notify load start
    delegate?.handleOnLoadStart()

    // Check if it's a network URL
    if uri.hasPrefix("http://") || uri.hasPrefix("https://") {
      loadRemoteImage(uri: uri)
    } else {
      loadLocalImage(uri: uri)
    }
  }

  // MARK: - Private Methods

  private func clearImage() {
    stopAnimation()
    decoder = nil
    metadata = nil
    frameBuffer.removeAll()
    decodingIndices.removeAll()
    image = nil
    currentFrameIndex = 0
    currentLoopCount = 0
    isAnimated = false
    retryCount = 0
    currentURL = nil
  }

  // MARK: - Image Loading

  private func loadRemoteImage(uri: String) {
    clearImage()

    guard let url = URL(string: uri) else {
      DispatchQueue.main.async { [weak self] in
        self?.delegate?.handleOnError(error: "Invalid URL: \(uri)")
      }
      return
    }

    currentURL = url
    retryCount = 0

    let config = URLSessionConfiguration.default
    let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    let downloadTask = session.downloadTask(with: url)
    downloadTask.resume()
  }

  private func loadLocalImage(uri: String) {
    clearImage()

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }

      var filePath = uri

      // Handle file:// prefix
      if uri.hasPrefix("file://") {
        filePath = String(uri.dropFirst(7))
      }

      let fileManager = FileManager.default

      // Try to load from bundle if not an absolute path
      if !fileManager.fileExists(atPath: filePath) {
        if let bundlePath = Bundle.main.path(forResource: uri, ofType: nil) {
          filePath = bundlePath
        } else {
          let fileName = (uri as NSString).deletingPathExtension
          let fileExt = (uri as NSString).pathExtension
          if let bundlePath = Bundle.main.path(forResource: fileName, ofType: fileExt) {
            filePath = bundlePath
          }
        }
      }

      guard fileManager.fileExists(atPath: filePath) else {
        DispatchQueue.main.async {
          self.delegate?.handleOnError(error: "Failed to load local file: \(uri)")
        }
        return
      }

      guard let data = fileManager.contents(atPath: filePath) else {
        DispatchQueue.main.async {
          self.delegate?.handleOnError(error: "Failed to read file: \(uri)")
        }
        return
      }

      self.decodeAvifData(data)
    }
  }

  // MARK: - AVIF Decoding

  private func decodeAvifData(_ data: Data) {
    AvifDecoder.loadMetadata(from: data) { [weak self] decoder, metadata, error in
      guard let self = self else { return }

      if let error = error {
        DispatchQueue.main.async {
          self.delegate?.handleOnError(error: error.localizedDescription)
          self.delegate?.handleOnLoadEnd()
        }
        return
      }

      guard let decoder = decoder, let metadata = metadata else {
        DispatchQueue.main.async {
          self.delegate?.handleOnError(error: "Failed to decode AVIF")
          self.delegate?.handleOnLoadEnd()
        }
        return
      }

      self.decoder = decoder
      self.metadata = metadata
      self.isAnimated = metadata.frameCount > 1

      // Prepare first frame and start animation if needed
      self.prepareFirstFrame()
    }
  }

  private func forceDecodeImage(_ image: UIImage?) -> UIImage? {
    guard let image = image, let cgImage = image.cgImage else {
      return image
    }

    let width = cgImage.width
    let height = cgImage.height

    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
      return image
    }

    let bitmapInfo =
      CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

    guard
      let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
      )
    else {
      return image
    }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    guard let newCgImage = context.makeImage() else {
      return image
    }

    return UIImage(cgImage: newCgImage, scale: image.scale, orientation: image.imageOrientation)
  }

  /// Decode only the first frame initially to be quick
  private func prepareFirstFrame() {
    guard let decoder = decoder, metadata != nil else { return }

    decodeQueue.async { [weak self] in
      autoreleasepool {
        guard let self = self, self.decoder != nil else { return }

        // Decode just the first frame
        var firstFrame = decoder.decodeFrame(at: 0)

        // Force decode before returning to main thread
        firstFrame = self.forceDecodeImage(firstFrame)

        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }

          if let firstFrame = firstFrame {
            self.image = firstFrame
            self.delegate?.handleOnLoad()
            self.delegate?.handleOnLoadEnd()

            if self.isAnimated {
              self.startAnimation()
            }
          } else {
            self.delegate?.handleOnError(error: "Failed to decode first frame")
            self.delegate?.handleOnLoadEnd()
          }
        }
      }
    }
  }

  private func preloadNextFrames() {
    guard let metadata = metadata else { return }

    let startIndex = (currentFrameIndex + 1) % metadata.frameCount

    // Schedule next 'bufferWindow' frames
    for i in 0..<bufferWindow {
      let index = (startIndex + i) % metadata.frameCount
      scheduleDecodeForFrame(index)
    }
  }

  private func scheduleDecodeForFrame(_ frameIndex: Int) {
    // Skip if already has it or already decoding
    guard frameBuffer[frameIndex] == nil, !decodingIndices.contains(frameIndex) else { return }
    guard decoder != nil else { return }

    decodingIndices.insert(frameIndex)

    decodeQueue.async { [weak self] in
      autoreleasepool {
        guard let self = self, let decoder = self.decoder else { return }

        var frame = decoder.decodeFrame(at: frameIndex)

        // Force decode before returning to main thread
        frame = self.forceDecodeImage(frame)

        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          self.decodingIndices.remove(frameIndex)

          if let frame = frame {
            self.frameBuffer[frameIndex] = frame
          }
        }
      }
    }
  }

  // MARK: - Animation

  private func startAnimation() {
    guard isAnimated, let metadata = metadata, metadata.frameCount > 0, !isPlaying else {
      return
    }

    isPlaying = true
    frameAccumulator = 0
    lastTimestamp = 0

    // Preload next frames immediately
    preloadNextFrames()

    displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation(_:)))
    displayLink?.add(to: .main, forMode: .common)
  }

  private func stopAnimation() {
    isPlaying = false
    displayLink?.invalidate()
    displayLink = nil
  }

  @objc private func updateAnimation(_ link: CADisplayLink) {
    guard let metadata = metadata else { return }

    if lastTimestamp == 0 {
      lastTimestamp = link.timestamp
      return
    }

    let delta = link.timestamp - lastTimestamp
    lastTimestamp = link.timestamp
    frameAccumulator += delta

    var currentFrameDuration = metadata.frameDurations[currentFrameIndex].doubleValue

    // Try to advance frames if accumulator covers the duration
    while frameAccumulator >= currentFrameDuration {
      var nextIndex = currentFrameIndex + 1
      if nextIndex >= metadata.frameCount {
        nextIndex = 0
      }

      if let nextImage = frameBuffer[nextIndex] {
        // We have the frame
        image = nextImage
        frameBuffer.removeValue(forKey: nextIndex)

        currentFrameIndex = nextIndex
        frameAccumulator -= currentFrameDuration

        // Update loop count after actually moving to 0
        if currentFrameIndex == 0 {
          currentLoopCount += 1
          if totalLoopCount > 0 && currentLoopCount >= totalLoopCount {
            stopAnimation()
            return
          }
        }

        // Update duration for the new frame
        currentFrameDuration = metadata.frameDurations[currentFrameIndex].doubleValue
      } else {
        // Frame not ready; avoid accumulator runaway to prevent stutter buildup.
        frameAccumulator = min(frameAccumulator, currentFrameDuration)
        break
      }
    }

    // Always ensure buffer is populated
    preloadNextFrames()
  }

  // MARK: - URLSessionDownloadDelegate

  public func urlSession(
    _ session: URLSession, downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    do {
      let data = try Data(contentsOf: location)
      decodeAvifData(data)
    } catch {
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        if self.retryCount < Self.maxRetryCount, let url = self.currentURL {
          self.retryCount += 1
          self.loadRemoteImage(uri: url.absoluteString)
        } else {
          self.delegate?.handleOnError(error: error.localizedDescription)
        }
      }
    }
  }

  public func urlSession(
    _ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?
  ) {
    if let error = error {
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        if self.retryCount < Self.maxRetryCount, let url = self.currentURL {
          self.retryCount += 1
          self.loadRemoteImage(uri: url.absoluteString)
        } else {
          self.delegate?.handleOnError(error: error.localizedDescription)
        }
      }
    }
  }
}
