//
//  MediaImageView.swift
//  react-native-media-view
//
//  Native media view using UIImageView (for images) and AVKit (for video)
//

import AVFoundation
import AVKit
import Foundation
import UIKit

/// Delegate protocol for handling media view events
@objc public protocol MediaImageViewDelegate: AnyObject {
  func handleOnLoadStart()
  func handleOnLoad()
  func handleOnLoadEnd()
  func handleOnError(error: String)
}

/// Native UIView subclass for displaying images and video content
@objcMembers
public class MediaImageViewCore: UIView {
  public weak var delegate: MediaImageViewDelegate?
  private var currentURI: String?
  private var currentResizeMode: String = "contain"

  // MARK: - Image display

  private lazy var imageView: UIImageView = {
    let iv = UIImageView()
    iv.clipsToBounds = true
    iv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    iv.backgroundColor = .clear
    return iv
  }()

  // MARK: - Video display

  private var queuePlayer: AVQueuePlayer?
  private var playerLayer: AVPlayerLayer?
  private var playerLooper: AVPlayerLooper?
  private var playerItem: AVPlayerItem?
  private var statusObservation: NSKeyValueObservation?
  private var loadingTask: URLSessionDataTask?

  // MARK: - Init

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupView()
  }

  private func setupView() {
    clipsToBounds = true
    backgroundColor = .clear
    isUserInteractionEnabled = false
    imageView.frame = bounds
    addSubview(imageView)
  }

  // MARK: - Layout

  public override func layoutSubviews() {
    super.layoutSubviews()
    imageView.frame = bounds
    playerLayer?.frame = bounds
  }

  // MARK: - Video detection

  private static let videoExtensions: Set<String> = [
    "mp4", "webm", "mov", "m4v", "avi", "mkv", "ogg", "ogv",
  ]

  private func isVideoURL(_ urlString: String) -> Bool {
    guard let url = URL(string: urlString) else { return false }
    let ext = url.pathExtension.lowercased()
    return Self.videoExtensions.contains(ext)
  }

  // MARK: - Public API

  public func setSource(_ source: NSDictionary) {
    guard let uri = source["uri"] as? String, !uri.isEmpty else {
      return
    }

    // Avoid reloading the same URI
    if uri == currentURI { return }

    delegate?.handleOnLoadStart()
    currentURI = uri

    // Clean up previous content
    cleanupVideo()
    cancelImageLoading()
    imageView.image = nil

    if isVideoURL(uri) {
      loadVideo(uri: uri)
    } else {
      loadImage(uri: uri)
    }
  }

  public func setResizeMode(_ resizeMode: String?) {
    guard let resizeMode, resizeMode != currentResizeMode else { return }
    currentResizeMode = resizeMode
    applyResizeMode()
  }

  // MARK: - Image Loading

  private func loadImage(uri: String) {
    imageView.isHidden = false

    guard let url = URL(string: uri) else {
      delegate?.handleOnError(error: "Invalid image URI")
      delegate?.handleOnLoadEnd()
      return
    }

    if url.isFileURL {
      loadImageFromFile(url: url)
    } else {
      loadImageFromNetwork(url: url)
    }
  }

  private func loadImageFromFile(url: URL) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      do {
        let data = try Data(contentsOf: url)
        guard let image = UIImage(data: data) else {
          DispatchQueue.main.async {
            self.delegate?.handleOnError(error: "Failed to decode image")
            self.delegate?.handleOnLoadEnd()
          }
          return
        }
        DispatchQueue.main.async {
          guard self.currentURI == url.absoluteString else { return }
          self.imageView.image = image
          self.applyResizeMode()
          self.delegate?.handleOnLoad()
          self.delegate?.handleOnLoadEnd()
        }
      } catch {
        DispatchQueue.main.async {
          self.delegate?.handleOnError(error: error.localizedDescription)
          self.delegate?.handleOnLoadEnd()
        }
      }
    }
  }

  private func loadImageFromNetwork(url: URL) {
    let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
      guard let self else { return }
      DispatchQueue.main.async {
        guard self.currentURI == url.absoluteString else { return }

        if let error {
          self.delegate?.handleOnError(error: error.localizedDescription)
          self.delegate?.handleOnLoadEnd()
          return
        }

        guard let data, let image = UIImage(data: data) else {
          self.delegate?.handleOnError(error: "Failed to decode image from network")
          self.delegate?.handleOnLoadEnd()
          return
        }

        self.imageView.image = image
        self.applyResizeMode()
        self.delegate?.handleOnLoad()
        self.delegate?.handleOnLoadEnd()
      }
    }
    loadingTask = task
    task.resume()
  }

  private func cancelImageLoading() {
    loadingTask?.cancel()
    loadingTask = nil
  }

  // MARK: - Video Loading

  private func loadVideo(uri: String) {
    imageView.isHidden = true

    guard let url = URL(string: uri) else {
      delegate?.handleOnError(error: "Invalid video URI")
      delegate?.handleOnLoadEnd()
      return
    }

    let item = AVPlayerItem(url: url)
    playerItem = item

    let player = AVQueuePlayer()
    queuePlayer = player
    player.isMuted = true

    // Loop playback indefinitely — looper manages item insertion
    playerLooper = AVPlayerLooper(player: player, templateItem: item)

    let pLayer = AVPlayerLayer(player: player)
    pLayer.frame = bounds
    playerLayer = pLayer
    layer.addSublayer(pLayer)
    applyVideoGravity()

    // Observe the player's currentItem status for readiness
    statusObservation = player.observe(\.currentItem?.status, options: [.new]) {
      [weak self] observedPlayer, _ in
      DispatchQueue.main.async {
        guard let self else { return }
        guard let currentItem = observedPlayer.currentItem else { return }
        switch currentItem.status {
        case .readyToPlay:
          self.delegate?.handleOnLoad()
          self.delegate?.handleOnLoadEnd()
          observedPlayer.play()
        case .failed:
          let msg = currentItem.error?.localizedDescription ?? "Unknown video error"
          self.delegate?.handleOnError(error: msg)
          self.delegate?.handleOnLoadEnd()
        default:
          break
        }
      }
    }
  }

  private func cleanupVideo() {
    statusObservation?.invalidate()
    statusObservation = nil
    queuePlayer?.pause()
    queuePlayer = nil
    playerLooper = nil
    playerItem = nil
    playerLayer?.removeFromSuperlayer()
    playerLayer = nil
  }

  // MARK: - Resize Mode

  private func applyResizeMode() {
    switch currentResizeMode {
    case "cover":
      imageView.contentMode = .scaleAspectFill
    case "contain":
      imageView.contentMode = .scaleAspectFit
    case "stretch":
      imageView.contentMode = .scaleToFill
    case "center":
      imageView.contentMode = .center
    default:
      imageView.contentMode = .scaleAspectFit
    }
    applyVideoGravity()
  }

  private func applyVideoGravity() {
    guard let playerLayer else { return }
    switch currentResizeMode {
    case "cover":
      playerLayer.videoGravity = .resizeAspectFill
    case "stretch":
      playerLayer.videoGravity = .resize
    default:
      playerLayer.videoGravity = .resizeAspect
    }
  }

  // MARK: - Cleanup

  deinit {
    cleanupVideo()
    cancelImageLoading()
  }
}
