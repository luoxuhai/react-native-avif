# react-native-media-view

A high-performance React Native component for displaying images (including AVIF) and videos using native platform APIs. Renders images via `UIImageView` and videos via `AVKit` — no WebView overhead. Supports iOS only with the new architecture (Fabric).

## Features

- **Native image rendering** — Uses `UIImageView` with `UIImage` for fast, memory-efficient display
- **AVIF support** — iOS 16+ decodes AVIF natively, including animated AVIF
- **Native video playback** — Uses `AVQueuePlayer` + `AVPlayerLayer` with seamless looping
- **Resize modes** — `contain`, `cover`, `stretch`, `center` (maps to `contentMode` / `videoGravity`)
- **Lifecycle events** — `onLoadStart`, `onLoad`, `onLoadEnd`, `onError`
- **No WebView, no third-party dependencies**

## Installation

```sh
npm install react-native-media-view
```

For iOS, install pods:

```sh
cd ios && pod install
```

## Metro Configuration

Add `avif` to your Metro asset extensions in `metro.config.js`:

```js
const { getDefaultConfig } = require('@react-native/metro-config');

const config = getDefaultConfig(__dirname);
config.resolver.assetExts.push('avif');

module.exports = config;
```

## Usage

```tsx
import { MediaView } from 'react-native-media-view';

// Local AVIF image
<MediaView
  source={require('./assets/image.avif')}
  resizeMode="contain"
  style={{ width: 300, height: 300 }}
  onLoad={() => console.log('Loaded')}
  onError={(e) => console.error(e.nativeEvent.error)}
/>

// Remote image
<MediaView
  source={{ uri: 'https://example.com/photo.avif' }}
  resizeMode="cover"
  style={{ width: '100%', aspectRatio: 16 / 9 }}
/>

// Video (auto-detected by file extension, loops + muted)
<MediaView
  source={{ uri: 'https://example.com/clip.mp4' }}
  resizeMode="cover"
  style={{ width: '100%', height: 200 }}
/>
```

## Props

| Prop         | Type                                            | Default      | Description                                |
| ------------ | ----------------------------------------------- | ------------ | ------------------------------------------ |
| `source`     | `ImageRequireSource \| { uri: string }`         | **required** | Image or video source (`require()` or URI) |
| `resizeMode` | `'contain' \| 'cover' \| 'stretch' \| 'center'` | `'contain'`  | How media fits the view                    |
| `style`      | `ViewStyle`                                     | —            | Standard React Native view style           |

## Events

| Event         | Payload     | Description                           |
| ------------- | ----------- | ------------------------------------- |
| `onLoadStart` | —           | Loading has begun                     |
| `onLoad`      | —           | Media is ready for display / playback |
| `onLoadEnd`   | —           | Loading finished (success or failure) |
| `onError`     | `{ error }` | An error occurred                     |

## How It Works

| Media type | Rendered with                     |
| ---------- | --------------------------------- |
| Image      | `UIImageView` (`UIImage(data:)`)  |
| Video      | `AVQueuePlayer` + `AVPlayerLayer` |

- **Images** are loaded asynchronously (file or network) and decoded via `UIImage`, which supports AVIF on iOS 16+.
- **Videos** are detected by file extension (`.mp4`, `.mov`, `.webm`, etc.) and played with `AVQueuePlayer` + `AVPlayerLooper` for seamless looping. Playback is muted by default.

## Requirements

- iOS 16.0+
- React Native 0.74+ (New Architecture / Fabric)

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
