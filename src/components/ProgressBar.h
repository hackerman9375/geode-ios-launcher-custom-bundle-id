#import <UIKit/UIKit.h>
#import "../RootViewController.h"

@interface ProgressBar : UIView

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, copy) NSString *progressText;
@property (nonatomic, assign) BOOL showCancelButton;
@property (nonatomic, strong) RootViewController *root;
//@property (weak, nonatomic) id<ProgressBarDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame
    progressText:(NSString *)progressText
    showCancelButton:(BOOL)showCancelButton
    root:(RootViewController*)root;

- (void)setProgress:(CGFloat)progress;
@end
