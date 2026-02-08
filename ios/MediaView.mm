//
//  MediaView.mm
//  react-native-media-view
//
//  React Native Fabric component binding for media view
//

#import "MediaView.h"
#if __has_include(<react_native_media_view/react_native_media_view-Swift.h>)
#import <react_native_media_view/react_native_media_view-Swift.h>
#else
#import "react_native_media_view-Swift.h"
#endif
#import <React/RCTConversions.h>

#import <react/renderer/components/MediaViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/MediaViewSpec/EventEmitters.h>
#import <react/renderer/components/MediaViewSpec/Props.h>
#import <react/renderer/components/MediaViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

@interface MediaView () <MediaImageViewDelegate, RCTMediaViewViewProtocol>
@end

@implementation MediaView {
  MediaImageViewCore *_view;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<MediaViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const MediaViewProps>();
    _props = defaultProps;

    _view = [[MediaImageViewCore alloc] init];
    _view.delegate = self;

    self.contentView = _view;
  }

  return self;
}

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps =
      *std::static_pointer_cast<MediaViewProps const>(_props);
  const auto &newViewProps =
      *std::static_pointer_cast<MediaViewProps const>(props);

  // Update source
  if (oldViewProps.source.uri != newViewProps.source.uri) {
    NSDictionary *sourceDict =
        @{@"uri" : RCTNSStringFromString(newViewProps.source.uri)};
    [_view setSource:sourceDict];
  }

  // Update resizeMode (aligned with React Native Image)
  if (oldViewProps.resizeMode != newViewProps.resizeMode) {
    [_view setResizeMode:RCTNSStringFromString(newViewProps.resizeMode)];
  }

  [super updateProps:props oldProps:oldProps];
}

#pragma mark - MediaImageViewDelegate

- (void)handleOnLoadStart {
  if (_eventEmitter != nil) {
    std::dynamic_pointer_cast<const MediaViewEventEmitter>(_eventEmitter)
        ->onLoadStart(MediaViewEventEmitter::OnLoadStart{});
  }
}

- (void)handleOnLoad {
  if (_eventEmitter != nil) {
    std::dynamic_pointer_cast<const MediaViewEventEmitter>(_eventEmitter)
        ->onLoad(MediaViewEventEmitter::OnLoad{});
  }
}

- (void)handleOnLoadEnd {
  if (_eventEmitter != nil) {
    std::dynamic_pointer_cast<const MediaViewEventEmitter>(_eventEmitter)
        ->onLoadEnd(MediaViewEventEmitter::OnLoadEnd{});
  }
}

- (void)handleOnErrorWithError:(NSString *)error {
  if (_eventEmitter != nil) {
    std::dynamic_pointer_cast<const MediaViewEventEmitter>(_eventEmitter)
        ->onError(MediaViewEventEmitter::OnError{
            .error = std::string([error UTF8String])});
  }
}

@end

Class<RCTComponentViewProtocol> MediaViewCls(void) { return MediaView.class; }
