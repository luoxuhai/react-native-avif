import { codegenNativeComponent } from 'react-native';
import type { ViewProps } from 'react-native';
import type {
  DirectEventHandler,
  Int32,
} from 'react-native/Libraries/Types/CodegenTypes';
import type { HostComponent } from 'react-native';

/**
 * Source props for AVIF image (resolved from require())
 */
export interface AvifSourceProps {
  /** URI of the AVIF image */
  uri?: string;
}

/**
 * Resize mode for image display (aligned with React Native Image)
 */
export type ResizeMode = 'cover' | 'contain' | 'stretch' | 'center';

/**
 * Native props for AvifView component
 */
interface NativeProps extends ViewProps {
  /** Source of the AVIF image */
  source?: AvifSourceProps;
  /** Number of times to loop the animation (0 = infinite) */
  loopCount?: Int32;
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

export type AvifViewComponent = HostComponent<NativeProps>;

export default codegenNativeComponent<NativeProps>(
  'AvifView'
) as AvifViewComponent;
