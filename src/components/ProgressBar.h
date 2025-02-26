#import <UIKit/UIKit.h>


@interface ProgressBar : UIView

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, copy) NSString *progressText;
@property (nonatomic, assign) BOOL showCancelButton;
//@property (weak, nonatomic) id<ProgressBarDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame
    progressText:(NSString *)progressText
    showCancelButton:(BOOL)showCancelButton;

- (void)setProgress:(CGFloat)progress;

@end
