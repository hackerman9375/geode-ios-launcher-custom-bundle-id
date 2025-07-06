#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, UIDocumentPickerDelegate>
@property(nonatomic, strong) UIImageView* logoImageView;
@property(nonatomic, strong) UILabel* titleLabel;
@property(nonatomic, strong) UILabel* optionalTextLabel;
@property(nonatomic, strong) UIButton* launchButton;
@property(nonatomic, strong) UIButton* settingsButton;

@property(strong, nonatomic) NSMutableArray* fishes;
@property(strong, nonatomic) UIImage* cachedFishAnimation;
@property(nonatomic) BOOL hasTappedFish;
@property(nonatomic) BOOL processOfTappedFish;
@property(nonatomic, strong) UIImpactFeedbackGenerator* impactFeedback;

- (void)updateState;
- (void)cancelDownload;

// sorry i dont want to deal with dumb link errors
- (BOOL)progressVisible;
- (void)progressVisibility:(BOOL)hidden;
- (void)progressCancelVisibility:(BOOL)hidden;
- (void)progressText:(NSString*)text;
- (void)barProgress:(CGFloat)value;
- (void)signApp:(BOOL)force completionHandler:(void (^)(BOOL success, NSString* error))completionHandler;
- (void)signAppWithSafeMode:(void (^)(BOOL success, NSString* error))completionHandler;
- (void)refreshTheme;
- (BOOL)bundleIPAWithPatch:(BOOL)safeMode withLaunch:(BOOL)launch;
- (void)launchHelper3;
- (void)launchHelper2:(BOOL)safeMode;
- (void)launchHelper:(BOOL)safeMode;
@end
