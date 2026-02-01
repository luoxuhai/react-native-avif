# react-native-avif

A React Native component for displaying AVIF images, including animated AVIF images. Supports iOS only with the new architecture (Fabric).

## Features

- Display static AVIF images
- Play animated AVIF images with frame-by-frame control
- Pause/resume animation with `paused` prop
- Control loop count (0 = infinite)
- Multiple content modes: contain, cover, stretch, center
- Events: onLoad, onStart, onStop, onEnd, onFrame, onError
- No third-party dependencies

## Installation

```sh
npm install react-native-avif
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
import { AvifView } from 'react-native-avif';

// Use require() to import local AVIF images
<AvifView
  source={require('./assets/image.avif')}
  style={{ width: 300, height: 300 }}
  contentMode="contain"
  paused={false}
  loopCount={0}
  onLoad={(event) => {
    const { duration, frameCount, width, height } = event.nativeEvent;
    console.log('Loaded:', { duration, frameCount, width, height });
  }}
  onStart={() => console.log('Animation started')}
  onStop={() => console.log('Animation paused')}
  onEnd={() => console.log('Animation ended')}
  onFrame={(event) => console.log('Frame:', event.nativeEvent.frameNumber)}
  onError={(event) => console.error('Error:', event.nativeEvent.error)}
/>;
```

## Props

| Prop          | Type                                            | Default     | Description                         |
| ------------- | ----------------------------------------------- | ----------- | ----------------------------------- |
| `source`      | `ImageRequireSource`                            | required    | AVIF image source (use `require()`) |
| `paused`      | `boolean`                                       | `false`     | Pause the animation                 |
| `loopCount`   | `number`                                        | `0`         | Number of loops (0 = infinite)      |
| `contentMode` | `'contain' \| 'cover' \| 'stretch' \| 'center'` | `'contain'` | How the image should fit            |
| `style`       | `ViewStyle`                                     | -           | Style for the view                  |

## Events

| Event     | Payload                                   | Description                                               |
| --------- | ----------------------------------------- | --------------------------------------------------------- |
| `onLoad`  | `{ duration, frameCount, width, height }` | Called when image is loaded                               |
| `onStart` | -                                         | Called when animation starts playing                      |
| `onStop`  | -                                         | Called when animation is paused                           |
| `onEnd`   | -                                         | Called when animation completes (last frame of last loop) |
| `onFrame` | `{ frameNumber }`                         | Called on each frame change (animated AVIF)               |
| `onError` | `{ error }`                               | Called when an error occurs                               |

## Requirements

- iOS 16.0+
- React Native 0.74+ (New Architecture / Fabric)

## Performance notes

- Animated AVIF frames are decoded on demand with a small look‑ahead buffer.
- For smooth playback, prefer reasonable frame sizes and durations.
- If you see stutter under heavy load, consider reducing frame count or resolution.

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
