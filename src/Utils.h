#import "Localization.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utils : NSObject
+ (NSString*)gdBundleName;
+ (NSString*)launcherBundleName;
+ (NSString*)getGeodeVersion;
+ (void)updateGeodeVersion:(NSString*)newVer;
+ (BOOL)isJailbroken;
+ (NSString*)getGeodeReleaseURL;
+ (NSString*)getGeodeLauncherURL;
+ (UIImageView*)imageViewFromPDF:(NSString*)pdfName;
+ (NSURL*)pathToMostRecentLogInDirectory:(NSString*)directoryPath;
+ (void)showErrorGlobal:(NSString*)title error:(NSError*)error;
+ (void)showError:(UIViewController*)root title:(NSString*)title error:(NSError*)error;
+ (void)showNotice:(UIViewController*)root title:(NSString*)title;
+ (NSString*)archName;
+ (void)toggleKey:(NSString*)key;
+ (NSString*)sha256sum:(NSString*)path;
+ (NSString*)getGDBinaryHash;
+ (NSString*)getGDDocPath;
+ (NSString*)getGDBinaryPath;
+ (NSString*)getGDBundlePath;
+ (NSUserDefaults*)getPrefs;
+ (BOOL)isSandboxed;
+ (const char*)getKillAllPath;
+ (void)increaseLaunchCount;
+ (void)tweakLaunch_withSafeMode:(BOOL)safemode;
@end
