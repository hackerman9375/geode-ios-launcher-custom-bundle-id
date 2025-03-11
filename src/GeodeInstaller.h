#import "RootViewController.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GeodeInstaller : NSObject <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>
@property(nonatomic, strong) RootViewController* root;
- (void)startInstall:(RootViewController*)root ignoreRoot:(BOOL)ignoreRoot;
- (void)checkUpdates:(RootViewController*)root download:(BOOL)download;
- (void)checkLauncherUpdates:(RootViewController*)root;
- (void)setVersion;
- (void)verifyChecksum;
- (void)cancelDownload;
@end
