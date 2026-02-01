//
//  AvifView.mm
//  react-native-avif
//
//  React Native Fabric component binding for AVIF image view
//

#import "AvifView.h"
#if __has_include(<react_native_avif/react_native_avif-Swift.h>)
#import <react_native_avif/react_native_avif-Swift.h>
#else
#import "react_native_avif-Swift.h"
#endif
#import <React/RCTConversions.h>

#import <react/renderer/components/AvifViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/AvifViewSpec/EventEmitters.h>
#import <react/renderer/components/AvifViewSpec/Props.h>
#import <react/renderer/components/AvifViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"



using namespace facebook::react;

@interface AvifView () <AvifImageViewDelegate, RCTAvifViewViewProtocol>
@end

@implementation AvifView {
  AvifImageViewCore *_view;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<AvifViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const AvifViewProps>();
    _props = defaultProps;

    _view = [[AvifImageViewCore alloc] init];
    _view.delegate = self;

    self.contentView = _view;
  }

  return self;
}

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps =
      *std::static_pointer_cast<AvifViewProps const>(_props);
  const auto &newViewProps =
      *std::static_pointer_cast<AvifViewProps const>(props);

  // Update source
  if (oldViewProps.source.uri != newViewProps.source.uri) {
    NSDictionary *sourceDict =
        @{@"uri" : RCTNSStringFromString(newViewProps.source.uri)};
    [_view setSource:sourceDict];
  }

  // Update loopCount
  if (oldViewProps.loopCount != newViewProps.loopCount) {
    [_view setLoopCount:newViewProps.loopCount];
  }

  // Update resizeMode (aligned with React Native Image)
  if (oldViewProps.resizeMode != newViewProps.resizeMode) {
    [_view setResizeMode:RCTNSStringFromString(newViewProps.resizeMode)];
  }

  [super updateProps:props oldProps:oldProps];
}

#pragma mark - AvifImageViewDelegate

- (void)handleOnLoadStart {
  if (_eventEmitter != nil) {
    std::dynamic_pointer_cast<const AvifViewEventEmitter>(_eventEmitter)
        ->onLoadStart(AvifViewEventEmitter::OnLoadStart{});
  }
}

- (void)handleOnLoad {
  if (_eventEmitter != nil) {
    std::dynamic_pointer_cast<const AvifViewEventEmitter>(_eventEmitter)
        ->onLoad(AvifViewEventEmitter::OnLoad{});
  }
}

- (void)handleOnLoadEnd {
  if (_eventEmitter != nil) {
    std::dynamic_pointer_cast<const AvifViewEventEmitter>(_eventEmitter)
        ->onLoadEnd(AvifViewEventEmitter::OnLoadEnd{});
  }
}

- (void)handleOnErrorWithError:(NSString *)error {
  if (_eventEmitter != nil) {
    std::dynamic_pointer_cast<const AvifViewEventEmitter>(_eventEmitter)
        ->onError(AvifViewEventEmitter::OnError{
            .error = std::string([error UTF8String])});
  }
}

@end

Class<RCTComponentViewProtocol> AvifViewCls(void) { return AvifView.class; }
