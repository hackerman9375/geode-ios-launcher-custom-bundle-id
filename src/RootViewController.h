#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>
@property(nonatomic, strong) UIImageView* logoImageView;
@property(nonatomic, strong) UILabel* titleLabel;
@property(nonatomic, strong) UILabel* optionalTextLabel;
@property(nonatomic, strong) UIButton* launchButton;
@property(nonatomic, strong) UIButton* settingsButton;
- (void)updateState;
- (void)cancelDownload;

// sorry i dont want to deal with dumb link errors
- (BOOL)progressVisible;
- (void)progressVisibility:(BOOL)hidden;
- (void)progressCancelVisibility:(BOOL)hidden;
- (void)progressText:(NSString*)text;
- (void)barProgress:(CGFloat)value;
- (void)signApp:(BOOL)force completionHandler:(void (^)(BOOL success, NSString* error))completionHandler;
@end
