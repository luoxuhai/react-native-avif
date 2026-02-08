import { codegenNativeComponent } from 'react-native';
import type { ViewProps } from 'react-native';
import type { DirectEventHandler } from 'react-native/Libraries/Types/CodegenTypes';
import type { HostComponent } from 'react-native';

/**
 * Source props for media (resolved from require())
 */
export interface MediaSourceProps {
  /** URI of the image or video */
  uri?: string;
}

/**
 * Resize mode for image display (aligned with React Native Image)
 */
export type ResizeMode = 'cover' | 'contain' | 'stretch' | 'center';

/**
 * Native props for MediaView component
 */
interface NativeProps extends ViewProps {
  /** Source of the media */
  source?: MediaSourceProps;
  /** Resize mode for image display (aligned with React Native Image) */
  resizeMode?: string;
  /** Callback when loading starts */
  onLoadStart?: DirectEventHandler<null>;
  /** Callback when the image is loaded */
  onLoad?: DirectEventHandler<null>;
  /** Callback when loading ends (success or failure) */
  onLoadEnd?: DirectEventHandler<null>;
  /** Callback when an error occurs */
  onError?: DirectEventHandler<Readonly<{ error: string }>>;
}

export type MediaViewComponent = HostComponent<NativeProps>;

export default codegenNativeComponent<NativeProps>(
  'MediaView'
) as MediaViewComponent;
