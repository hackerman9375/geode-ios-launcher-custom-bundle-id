#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utils : NSObject
+ (NSString*)gdBundleName;
+ (NSString*)getGeodeVersion;
+ (void)updateGeodeVersion:(NSString*)newVer;
+ (BOOL)isJailbroken;
+ (NSString*)getGeodeReleaseURL;
+ (UIImageView *)imageViewFromPDF:(NSString *)pdfName;
+ (NSURL *)pathToMostRecentLogInDirectory:(NSString *)directoryPath;
+ (void)showError:(UIViewController*)root title:(NSString *)title error:(NSError*)error;
+ (NSString*)archName;
+ (void)toggleKey:(NSString*)key;
@end

