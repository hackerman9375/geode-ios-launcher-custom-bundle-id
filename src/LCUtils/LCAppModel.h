#import "src/LCUtils/LCAppInfo.h"
#import "src/LCUtils/LCContainer.h"
#import "src/LCUtils/LCUtils.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol LCAppModelDelegate <NSObject>
- (void)closeNavigationView;
- (void)changeAppVisibility:(id<NSObject>)app;
@end

@interface LCAppModel : NSObject 

@property LCAppInfo *appInfo;

@property BOOL isAppRunning;
@property BOOL isSigningInProgress;
@property CGFloat signProgress;
@property BOOL uiIsJITNeeded;
@property BOOL uiIsHidden;
@property BOOL uiIsLocked;
@property BOOL uiIsShared;
@property NSString *uiDefaultDataFolder;
@property NSArray *uiContainers;
@property LCContainer *uiSelectedContainer;
@property NSString *uiTweakFolder;
@property BOOL uiDoSymlinkInbox;
@property BOOL uiUseLCBundleId;
@property BOOL uiBypassAssertBarrierOnQueue;
@property Signer *uiSigner;
@property BOOL uiIgnoreDlopenError;
@property BOOL uiFixBlackScreen;
@property NSString *uiSelectedLanguage;
@property NSArray *supportedLanaguages;

@property id<LCAppModelDelegate> delegate;

- (instancetype)initWithAppInfo:(LCAppInfo *)appInfo delegate:(id<LCAppModelDelegate>)delegate;

- (BOOL)isEqual:(id<NSObject>)object;
- (NSUInteger)hash;
- (void)runAppWithContainerFolderName:(NSString *)containerFolderName error:(NSError **)error;
- (void)forceResignWithCompletion:(void (^)(NSError *error))completion;
- (void)signAppWithForce:(BOOL)force completion:(void (^)(NSError *error))completion;
- (void)jitLaunch;
- (void)setLocked:(BOOL)locked completion:(void (^)(NSError *error))completion;
- (void)toggleHidden;

@end
