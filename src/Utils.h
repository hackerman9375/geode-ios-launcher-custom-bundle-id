#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utils : NSObject
+ (NSString*)gdBundleName;
+ (NSString*)launcherBundleName;
+ (NSString*)getGeodeVersion;
+ (NSString*)getGeodeDebURL;
+ (void)updateGeodeVersion:(NSString*)newVer;
+ (BOOL)isJailbroken;
+ (NSString*)getGeodeReleaseURL;
+ (UIImageView *)imageViewFromPDF:(NSString *)pdfName;
+ (NSURL *)pathToMostRecentLogInDirectory:(NSString *)directoryPath;
+ (void)showErrorGlobal:(NSString *)title error:(NSError *)error;
+ (void)showError:(UIViewController*)root title:(NSString *)title error:(NSError*)error;
+ (void)showNotice:(UIViewController*)root title:(NSString *)title;
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
@end
