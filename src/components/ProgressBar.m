#import "ProgressBar.h"
#import "../Theming.h"

@interface ProgressBar ()

@property (nonatomic, strong) UIView *progressView;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UIButton *cancelButton;

@end

@implementation ProgressBar 

- (instancetype)initWithFrame:(CGRect)frame
    progressText:(NSString *)progressText
    showCancelButton:(BOOL)showCancelButton
    root:(RootViewController*)root {
    self = [super initWithFrame:frame];
    if (self) {
        self.progressText = progressText;
        self.showCancelButton = showCancelButton;
        self.backgroundColor = [UIColor clearColor];
        self.root = root;

        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    CGFloat barHeight = 10.0; // height of the bar
    CGFloat textHeight = 20.0; // height of the text
    CGFloat buttonHeight = 30.0; // height of the button
    CGFloat spacing = 8.0; // spacing between

    if (self.progressText != nil) {
        self.progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, textHeight)];
        self.progressLabel.textAlignment = NSTextAlignmentCenter;
        self.progressLabel.textColor = [Theming getWhiteColor];
        self.progressLabel.text = [self.progressText stringByReplacingOccurrencesOfString:@"{percent}" withString:@"0"]; // Initialize with 0%
        [self addSubview:self.progressLabel];
    }

    CGRect barFrame = CGRectMake(0, self.progressText ? textHeight + spacing : 0, self.frame.size.width, barHeight);
    UIView *barBackgroundView = [[UIView alloc] initWithFrame:barFrame];
    barBackgroundView.backgroundColor = [Theming getDarkColor];
    barBackgroundView.layer.cornerRadius = barHeight / 2.0;
    barBackgroundView.clipsToBounds = YES;
    [self addSubview:barBackgroundView];

    self.progressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, barHeight)];
    self.progressView.backgroundColor = [Theming getAccentColor];
    self.progressView.layer.cornerRadius = barHeight / 2.0;
    self.progressView.clipsToBounds = YES;
    [barBackgroundView addSubview:self.progressView];

    if (self.showCancelButton) {
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[Theming getAccentColor] forState:UIControlStateNormal];
        self.cancelButton.frame = CGRectMake(0, barFrame.origin.y + barHeight + spacing, self.frame.size.width, buttonHeight);
        [self.cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.cancelButton];
    }
}

- (void)setProgress:(CGFloat)progress {
    if (progress < 0) progress = 0;
    if (progress > 100) progress = 100;
    _progress = progress;
    CGFloat barWidth = (self.frame.size.width * progress) / 100.0;
    self.progressView.frame = CGRectMake(0, 0, barWidth, self.progressView.frame.size.height);
    if (self.progressText) {
        NSString *progressText = [NSString stringWithFormat:@"%.0f", progress];
        self.progressLabel.text = [self.progressText stringByReplacingOccurrencesOfString:@"{percent}" withString:progressText];
    }
}

- (void)cancelButtonTapped {
    [_root cancelDownload];
}

- (void)setCancelHidden:(BOOL)hidden {
    if (self.cancelButton != nil) {
        [self.cancelButton setHidden:hidden];
    }
}

@end
