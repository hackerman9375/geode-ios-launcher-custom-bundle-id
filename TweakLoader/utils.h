@import Foundation;
@import ObjectiveC;

void swizzle(Class class, SEL originalAction, SEL swizzledAction);
void swizzleClassMethod(Class class, SEL originalAction, SEL swizzledAction);

// Exported from the main executable
@interface NSUserDefaults(LiveContainer)
+ (instancetype)gcSharedDefaults;
+ (instancetype)gcUserDefaults;
+ (NSString *)gcAppUrlScheme;
+ (NSString *)gcAppGroupPath;
+ (NSBundle *)gcMainBundle;
+ (NSDictionary*)guestAppInfo;
@end
