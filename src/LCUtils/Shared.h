#import "src/LCUtils/LCAppModel.h"
#import <Foundation/Foundation.h>

@interface LCPath : NSObject

+ (NSURL*)docPath;
+ (NSURL*)bundlePath;
+ (NSURL*)dataPath;
+ (NSURL*)appGroupPath;
+ (NSURL*)tweakPath;
+ (NSURL*)realLCDocPath;
+ (NSURL*)lcGroupDocPath;
+ (NSURL*)lcGroupBundlePath;
+ (NSURL*)lcGroupDataPath;
+ (NSURL*)lcGroupAppGroupPath;
+ (NSURL*)lcGroupTweakPath;
+ (void)ensureAppGroupPaths:(NSError**)error;

@end

@interface SharedModel : NSObject
@property BOOL isHiddenAppUnlocked;
@property BOOL developerMode;
// 0= not installed, 1= is installed, 2=current liveContainer is the second one

@property NSMutableArray<LCAppModel*>* apps;
@property NSMutableArray<LCAppModel*>* hiddenApps;

- (BOOL)isPhone;

@end
