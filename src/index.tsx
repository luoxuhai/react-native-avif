import type { ComponentProps } from 'react';
import { type ImageRequireSource, Image } from 'react-native';
import AvifViewNativeComponent, {
  type AvifViewComponent,
  type AvifSourceProps,
  type ResizeMode,
} from './AvifViewNativeComponent';

export type { AvifSourceProps, ResizeMode, AvifViewComponent };

/** @deprecated Use ResizeMode instead */
export type ContentMode = ResizeMode;

type NativeProps = ComponentProps<typeof AvifViewNativeComponent>;

export interface AvifViewProps extends Omit<NativeProps, 'source'> {
  /** Source of the AVIF image/video - use require('./path/to/file') or { uri: 'https://...' } */
  source: ImageRequireSource | { uri: string };
  /** Resize mode for display (aligned with React Native Image) */
  resizeMode?: ResizeMode;
}

/**
 * AvifView - A React Native component for displaying AVIF images and videos
 * Supports both static and animated AVIF images, and video files (mp4, webm, mov, etc.)
 * Video URIs are automatically detected by file extension and rendered with autoplay, loop, muted, playsinline.
 */
export function AvifView(props: AvifViewProps) {
  const { source, resizeMode = 'contain', ...restProps } = props;

  let resolvedSource: AvifSourceProps;

  if (typeof source === 'object' && 'uri' in source) {
    resolvedSource = { uri: source.uri };
  } else {
    const resolved = Image.resolveAssetSource(source as ImageRequireSource);
    resolvedSource = { uri: resolved?.uri || '' };
  }

  return (
    <AvifViewNativeComponent
      {...restProps}
      source={resolvedSource}
      resizeMode={resizeMode}
    />
  );
}

export default AvifView;
