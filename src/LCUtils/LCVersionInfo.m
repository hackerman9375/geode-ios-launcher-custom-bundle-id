#import "LCVersionInfo.h"

@implementation LCVersionInfo
+ (NSString*)getVersionStr {
    return [NSString stringWithFormat:@"Version %@-%s (%s/%s)",
        NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
        "release", "0", "0"];
}
@end
