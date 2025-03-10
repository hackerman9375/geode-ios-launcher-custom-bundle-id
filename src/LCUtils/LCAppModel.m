#import "LCAppModel.h"
#import "src/LCUtils/LCUtils.h"

@implementation LCAppModel

@synthesize isAppRunning = _isAppRunning;
@synthesize isSigningInProgress = _isSigningInProgress;

- (instancetype)initWithAppInfo:(LCAppInfo *)appInfo delegate:(id<LCAppModelDelegate>)delegate {
    if (self = [super init]) {
        _appInfo = appInfo;
        _delegate = delegate;
    }
    return self;
}

- (BOOL)isEqual:(id<NSObject>)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[LCAppModel class]]) {
        return NO;
    }
    return [self hash] == [object hash];
}

@end
