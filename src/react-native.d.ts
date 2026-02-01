// Type declarations for React Native internal modules
// These are required for React Native Fabric component codegen

declare module 'react-native/Libraries/Types/CodegenTypes' {
  export type Double = number;
  export type Float = number;
  export type Int32 = number;
  export type UnsafeObject = object;
  export type WithDefault<T, _V> = T | _V | undefined;
  export type DirectEventHandler<T> = (event: { nativeEvent: T }) => void;
  export type BubblingEventHandler<T> = (event: { nativeEvent: T }) => void;
}

declare module 'react-native/Libraries/Utilities/codegenNativeComponent' {
  import type { HostComponent } from 'react-native';

  export default function codegenNativeComponent<P>(
    componentName: string,
    options?: {
      interfaceOnly?: boolean;
      paperComponentName?: string;
      excludedPlatforms?: string[];
    }
  ): HostComponent<P>;
}

declare module 'react-native/Libraries/Utilities/codegenNativeCommands' {
  export default function codegenNativeCommands<T>(options: {
    supportedCommands: ReadonlyArray<keyof T>;
  }): T;
}
