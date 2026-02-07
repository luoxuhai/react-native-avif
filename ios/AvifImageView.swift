//
//  AvifImageView.swift
//  react-native-avif
//
//  AVIF image view implementation - decodes all frames upfront for smooth playback
//

import Foundation
import UIKit
import WebKit

/// Delegate protocol for handling AVIF image view events
@objc public protocol AvifImageViewDelegate: AnyObject {
  func handleOnLoadStart()
  func handleOnLoad()
  func handleOnLoadEnd()
  func handleOnError(error: String)
}

/// WKWebView subclass for displaying AVIF images with animation support
@objcMembers
public class AvifImageViewCore: WKWebView, WKNavigationDelegate {
  public weak var delegate: AvifImageViewDelegate?
  private var currentURI: String?
  private var currentResizeMode: String = "contain"

  public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
    super.init(frame: frame, configuration: configuration)
    configureWebView()
  }

  public required init?(coder: NSCoder) {
    let configuration = WKWebViewConfiguration()
    super.init(frame: .zero, configuration: configuration)
    configureWebView()
  }

  private func configureWebView() {
    navigationDelegate = self
    isOpaque = false
    backgroundColor = .clear
    scrollView.isScrollEnabled = false
    scrollView.bounces = false
    isUserInteractionEnabled = false
  }

  public func setSource(_ source: NSDictionary) {
    guard let uri = source["uri"] as? String, !uri.isEmpty else {
      return
    }

    delegate?.handleOnLoadStart()

    currentURI = uri

    if let url = URL(string: uri), url.isFileURL {
      loadHTMLForURL(url, baseURL: url.deletingLastPathComponent())
      return
    }

    if let url = URL(string: uri) {
      loadHTMLForURL(url, baseURL: nil)
      return
    }

    delegate?.handleOnError(error: "Invalid image URI")
    delegate?.handleOnLoadEnd()
  }

  public func setResizeMode(_ resizeMode: String?) {
    if let resizeMode {
      currentResizeMode = resizeMode
    }

    if let uri = currentURI, let url = URL(string: uri) {
      if url.isFileURL {
        loadHTMLForURL(url, baseURL: url.deletingLastPathComponent())
      } else {
        loadHTMLForURL(url, baseURL: nil)
      }
    }
  }

  private func loadHTMLForURL(_ url: URL, baseURL: URL?) {
    let html = buildHTML(imageURL: url.absoluteString, resizeMode: currentResizeMode)
    loadHTMLString(html, baseURL: baseURL)
  }

  private static let videoExtensions: Set<String> = [
    "mp4", "webm", "mov", "m4v", "avi", "mkv", "ogg", "ogv",
  ]

  private func isVideoURL(_ urlString: String) -> Bool {
    let ext = (urlString.lowercased() as NSString).pathExtension
    return Self.videoExtensions.contains(ext)
  }

  private func buildHTML(imageURL: String, resizeMode: String) -> String {
    let objectFit = cssObjectFit(for: resizeMode)
    let objectPosition = cssObjectPosition(for: resizeMode)
    let isVideo = isVideoURL(imageURL)
    let mediaTag = isVideo ? "video" : "img"
    let mediaElement =
      isVideo
      ? "<video src=\"\(imageURL)\" autoplay loop muted playsinline />"
      : "<img src=\"\(imageURL)\" />"
    return """
      <!doctype html>
      <html>
        <head>
          <meta name=\"viewport\" content=\"width=device-width, height=device-height, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\" />
          <style>
            html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: transparent; }
            html, body, \(mediaTag) { -webkit-user-select: none; user-select: none; -webkit-touch-callout: none; }
            \(mediaTag) { width: 100%; height: 100%; object-fit: \(objectFit); object-position: \(objectPosition); pointer-events: none; }
          </style>
        </head>
        <body>
          \(mediaElement)
        </body>
      </html>
      """
  }

  private func cssObjectFit(for resizeMode: String) -> String {
    switch resizeMode {
    case "cover":
      return "cover"
    case "contain":
      return "contain"
    case "center":
      return "none"
    case "stretch":
      return "fill"
    default:
      return "contain"
    }
  }

  private func cssObjectPosition(for resizeMode: String) -> String {
    switch resizeMode {
    case "center":
      return "center"
    default:
      return "center"
    }
  }

  public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    delegate?.handleOnLoad()
    delegate?.handleOnLoadEnd()
  }

  public func webView(
    _ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error
  ) {
    delegate?.handleOnError(error: error.localizedDescription)
    delegate?.handleOnLoadEnd()
  }

  public func webView(
    _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    delegate?.handleOnError(error: error.localizedDescription)
    delegate?.handleOnLoadEnd()
  }
}
