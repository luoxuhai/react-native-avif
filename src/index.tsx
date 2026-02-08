import type { ComponentProps } from 'react';
import { type ImageRequireSource, Image } from 'react-native';
import MediaViewNativeComponent, {
  type MediaViewComponent,
  type MediaSourceProps,
  type ResizeMode,
} from './MediaViewNativeComponent';

export type { MediaSourceProps, ResizeMode, MediaViewComponent };

/** @deprecated Use ResizeMode instead */
export type ContentMode = ResizeMode;

type NativeProps = ComponentProps<typeof MediaViewNativeComponent>;

export interface MediaViewProps extends Omit<NativeProps, 'source'> {
  /** Source of the media - use require('./path/to/file') or { uri: 'https://...' } */
  source: ImageRequireSource | { uri: string };
  /** Resize mode for display (aligned with React Native Image) */
  resizeMode?: ResizeMode;
}

/**
 * MediaView - A React Native component for displaying images and videos
 * Supports AVIF, PNG, JPEG, GIF, WebP images, and video files (mp4, webm, mov, etc.)
 * Video URIs are automatically detected by file extension and rendered with autoplay, loop, muted, playsinline.
 */
export function MediaView(props: MediaViewProps) {
  const { source, resizeMode = 'contain', ...restProps } = props;

  let resolvedSource: MediaSourceProps;

  if (typeof source === 'object' && 'uri' in source) {
    resolvedSource = { uri: source.uri };
  } else {
    const resolved = Image.resolveAssetSource(source as ImageRequireSource);
    resolvedSource = { uri: resolved?.uri || '' };
  }

  return (
    <MediaViewNativeComponent
      {...restProps}
      source={resolvedSource}
      resizeMode={resizeMode}
    />
  );
}

export default MediaView;
