#import "RootViewController.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VerifyInstall : NSObject
+ (BOOL)verifyGDAuthenticity;
+ (void)startVerifyGDAuth:(RootViewController*)root;
+ (BOOL)canLaunchAppWithBundleID:(NSString*)bundleID;
+ (BOOL)verifyGDInstalled;
+ (void)startGDInstall:(RootViewController*)root url:(NSURL*)url;
+ (BOOL)verifyGeodeInstalled;
//+ (void)startGeodeInstall;
+ (BOOL)verifyAll;
@end
