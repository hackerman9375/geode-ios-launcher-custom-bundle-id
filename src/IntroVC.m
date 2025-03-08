#import "IntroVC.h"
#import "src/LCUtils/Shared.h"
#include <stdlib.h>
#import "RootViewController.h"
#import "Theming.h"
#import "Utils.h"

@implementation IntroVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self showWelcomeStep];
}
#pragma mark - UI

- (void)goToNextStep {
    switch (_currentStep) {
        case InstallStepWelcome:
            _currentStep = InstallStepAccentColor;
            [self showAccentColorStep];
            break;
        case InstallStepAccentColor:
            if (_skipColor == NO) {
                [Theming saveAccentColor:_accentColor];
            }
            if ([Utils isJailbroken]) {
                _currentStep = InstallStepInstallMethod;
                [self showInstallMethodStep];
            } else {
                /*_currentStep = InstallStepLaunchMethod;
                [self showLaunchMethodStep];*/
                _currentStep = InstallStepWarning;
                [self showWarningStep];
            }
            break;
        case InstallStepInstallMethod:
            if ([_installMethod isEqualToString:@"Tweak"]) {
                _currentStep = InstallStepJailbreakStore;
                [self showJailbreakStoreStep];
            } else {
                if (![Utils isSandboxed]) {
                    [Utils showNotice:self title:@"You are using the TrollStore version of the launcher! Please note that launching with JIT may not work.\nIt's recommended to relaunch the app and install the tweak instead!"];
                }
                _currentStep = InstallStepComplete;
                [self completeSetup];
            }
            break;
        case InstallStepWarning:
        case InstallStepLaunchMethod:
            _currentStep = InstallStepComplete;
            [self completeSetup];
            break;
        case InstallStepJailbreakStore:
            _currentStep = InstallStepComplete;
            [self completeSetup];
            break;
        default:
            break;
    }
}

- (UIButton*)addNextButton {
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    nextButton.backgroundColor = [Theming getAccentColor];
    nextButton.clipsToBounds = YES;
    nextButton.layer.cornerRadius = 22.5;
    [nextButton setTitle:@"Next" forState:UIControlStateNormal];
    nextButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
    nextButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 8);
    [nextButton setImage:[[UIImage systemImageNamed:@"play.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [nextButton setTitleColor:[Theming getTextColor:[Theming getAccentColor]] forState:UIControlStateNormal];
    [nextButton setTintColor:[Theming getTextColor:[Theming getAccentColor]]];
    [nextButton addTarget:self action:@selector(goToNextStep) forControlEvents:UIControlEventTouchUpInside];
    return nextButton;
}

#pragma mark - View Transition

- (void)transitionToView:(UIView *)newView {
    [UIView animateWithDuration:0.3 animations:^{
        for (UIView *subview in self.view.subviews) {
            subview.alpha = 0.0;
        }
    } completion:^(BOOL finished) {
        [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        newView.alpha = 0.0;
        newView.frame = self.view.bounds;
        newView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:newView];
        [UIView animateWithDuration:0.3 animations:^{
            newView.alpha = 1.0;
        }];
    }];
}

#pragma mark - Step Views

- (void)showWarningStep {
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];

    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"exclamationmark.triangle"]];
    logoImageView.clipsToBounds = YES;
    [logoImageView setTintColor:[Theming getAccentColor]];
    //[41, 36].map(x => x * 6);
    float sizeMult = 7.F;
    logoImageView.frame = CGRectMake(view.center.x - ((41 * sizeMult) / 2), (view.bounds.size.height / 8) - 20, 41 * sizeMult, 36 * sizeMult);
    [view addSubview:logoImageView];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Warning";
    titleLabel.textColor = [Theming getWhiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:48];
    titleLabel.frame = CGRectMake(0, CGRectGetMaxY(logoImageView.frame) + 40, view.bounds.size.width, 60);
    [view addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"If you are not jailbroken or don't have TrollStore, you will need a Computer to set up JIT. JIT is required for Geode, and will not work when installed with an Enterprise Certificate.\n\nPlease refrain from asking about this.";
    subtitleLabel.numberOfLines = 10;
    subtitleLabel.textColor = [Theming getFooterColor];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [UIFont systemFontOfSize:14];
    subtitleLabel.frame = CGRectMake(30, CGRectGetMaxY(titleLabel.frame) + 5, view.bounds.size.width - 60, 170);
    [view addSubview:subtitleLabel];

    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    nextButton.backgroundColor = [Theming getAccentColor];
    nextButton.clipsToBounds = YES;
    nextButton.layer.cornerRadius = 22.5;
    [nextButton setTitle:@"Understood" forState:UIControlStateNormal];
    nextButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
    nextButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 8);
    [nextButton setImage:[[UIImage systemImageNamed:@"checkmark.circle.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [nextButton setTitleColor:[Theming getTextColor:[Theming getAccentColor]] forState:UIControlStateNormal];
    [nextButton setTintColor:[Theming getTextColor:[Theming getAccentColor]]];
    [nextButton addTarget:self action:@selector(goToNextStep) forControlEvents:UIControlEventTouchUpInside];
    
    nextButton.frame = CGRectMake(view.center.x - 70, CGRectGetMaxY(subtitleLabel.frame), 140, 45);
    [view addSubview:nextButton];

    [self transitionToView:view];
}

- (void)showWelcomeStep {
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];

    UIImageView *logoImageView = [Utils imageViewFromPDF:@"geode_logo"];
    if (logoImageView) {
        logoImageView.layer.cornerRadius = 50;
        logoImageView.clipsToBounds = YES;
        logoImageView.frame = CGRectMake(view.center.x - 75, view.center.y - 130, 150, 150);
        [view addSubview:logoImageView];
    } else {
        //self.logoImageView.backgroundColor = [UIColor redColor];
    }

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Welcome to Geode!";
    titleLabel.textColor = [Theming getWhiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:32];
    titleLabel.frame = CGRectMake(0, CGRectGetMaxY(logoImageView.frame) + 20, view.bounds.size.width, 44);
    [view addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"Let's get you started.";
    subtitleLabel.textColor = [Theming getFooterColor];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [UIFont systemFontOfSize:16];
    subtitleLabel.frame = CGRectMake(0, CGRectGetMaxY(titleLabel.frame) + 10, view.bounds.size.width, 30);
    [view addSubview:subtitleLabel];

    UIButton *nextButton = [self addNextButton];
    nextButton.frame = CGRectMake(view.center.x - 70, CGRectGetMaxY(subtitleLabel.frame) + 20, 140, 45);
    [view addSubview:nextButton];

    [self transitionToView:view];
}

- (void)showAccentColorStep {
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Choose your Accent Color";
    titleLabel.textColor = [Theming getWhiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:24];
    titleLabel.frame = CGRectMake(0, 80, view.bounds.size.width, 45);
    [view addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"You can change this later in the Settings.";
    subtitleLabel.textColor = [Theming getFooterColor];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [UIFont systemFontOfSize:16];
    subtitleLabel.frame = CGRectMake(0, CGRectGetMaxY(titleLabel.frame) + 10, view.bounds.size.width, 30);
    [view addSubview:subtitleLabel];

    UIButton *colorButton = [UIButton buttonWithType:UIButtonTypeSystem];
    colorButton.backgroundColor = [Theming getDarkColor];
    colorButton.clipsToBounds = YES;
    colorButton.layer.cornerRadius = 22.5;
    [colorButton setTitle:@"Change Color" forState:UIControlStateNormal];
    colorButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
    colorButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 8);
    [colorButton setImage:[[UIImage systemImageNamed:@"circle.lefthalf.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [colorButton setTitleColor:[Theming getWhiteColor] forState:UIControlStateNormal];
    [colorButton setTintColor:[Theming getWhiteColor]];
    [colorButton addTarget:self action:@selector(onColorClickButton) forControlEvents:UIControlEventTouchUpInside];
    colorButton.frame = CGRectMake(view.center.x - 80, view.center.y + 40, 150, 45);
    [view addSubview:colorButton];

    self.colorPreviewLabel = [[UILabel alloc] init];
    self.colorPreviewLabel.text = @"Preview";
    self.colorPreviewLabel.textColor = [Theming getAccentColor];
    self.colorPreviewLabel.textAlignment = NSTextAlignmentCenter;
    self.colorPreviewLabel.font = [UIFont systemFontOfSize:32];
    self.colorPreviewLabel.frame = CGRectMake(0, view.center.y - 40, view.bounds.size.width, 30);
    [view addSubview:self.colorPreviewLabel];
    
    self.colorNextButton = [self addNextButton];
    self.colorNextButton.frame = CGRectMake(view.center.x - 130, view.bounds.size.height - 150, 140, 45);
    [view addSubview:self.colorNextButton];

    UIButton *skipButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [skipButton setTitle:@"Skip" forState:UIControlStateNormal];
    [skipButton setTitleColor:[Theming getFooterColor] forState:UIControlStateNormal];
    skipButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [skipButton addTarget:self action:@selector(colorSkipPressed) forControlEvents:UIControlEventTouchUpInside];
    skipButton.frame = CGRectMake(CGRectGetMaxX(self.colorNextButton.frame) + 30, view.bounds.size.height - 150, 70, 45);
    [view addSubview:skipButton];
    [self transitionToView:view];
}

- (void)showInstallMethodStep {
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Installation Method";
    titleLabel.textColor = [Theming getWhiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:24];
    titleLabel.frame = CGRectMake(0, 80, view.bounds.size.width, 45);
    [view addSubview:titleLabel];

    int maximumImageSize = view.bounds.size.width / 4;

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"You can change this later in the Settings.";
    subtitleLabel.textColor = [Theming getFooterColor];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [UIFont systemFontOfSize:16];
    subtitleLabel.frame = CGRectMake(0, CGRectGetMaxY(titleLabel.frame) + 10, view.bounds.size.width, 30);
    [view addSubview:subtitleLabel];

    UIView *normalOptionContainer = [[UIView alloc] initWithFrame:CGRectMake(25, view.bounds.size.height/4, view.bounds.size.width, view.bounds.size.height/5)];

    UIImageView *normalIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, maximumImageSize, maximumImageSize)];
    normalIcon.contentMode = UIViewContentModeScaleAspectFit;
    normalIcon.tintColor = [Theming getAccentColor];
    UIImage *shieldImage = [UIImage systemImageNamed:@"shield.lefthalf.filled" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:60]];
    normalIcon.image = shieldImage;
    [normalOptionContainer addSubview:normalIcon];

    UIButton *normalRadioButton = [UIButton buttonWithType:UIButtonTypeCustom];
    normalRadioButton.frame = CGRectMake(CGRectGetMaxX(normalIcon.frame) + 10, 10, 30, 30);
    normalRadioButton.layer.cornerRadius = 15;
    normalRadioButton.layer.borderWidth = 2;
    normalRadioButton.layer.borderColor = [Theming getFooterColor].CGColor;
    normalRadioButton.tag = 1;
    [normalRadioButton addTarget:self action:@selector(radioButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [normalOptionContainer addSubview:normalRadioButton];

    UILabel *normalLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(normalRadioButton.frame) + 10, 10, view.bounds.size.width - 160, 30)];
    normalLabel.text = @"Normal (Recommended)";
    //lock.open
    normalLabel.textColor = [Theming getWhiteColor];
    normalLabel.font = [UIFont boldSystemFontOfSize:16];
    [normalOptionContainer addSubview:normalLabel];

    UILabel *normalDescription = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(normalIcon.frame) + 10, CGRectGetMaxY(normalLabel.frame) + 10, view.bounds.size.width - 150, view.bounds.size.height/8)];
    normalDescription.text = @"This method works between all iOS devices, jailbroken or not. However, you will have to launch the app with JIT every time you want to open Geode.";
    normalDescription.textColor = [Theming getFooterColor];
    normalDescription.font = [UIFont systemFontOfSize:13];
    normalDescription.numberOfLines = 5;
    [normalOptionContainer addSubview:normalDescription];

    [view addSubview:normalOptionContainer];

    // =============
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(40, CGRectGetMaxY(normalOptionContainer.frame) + 10, view.bounds.size.width - 80, 1)];
    separator.backgroundColor = [UIColor darkGrayColor];
    [view addSubview:separator];
    // =============

    UIView *tweakOptionContainer = [[UIView alloc] initWithFrame:CGRectMake(25, CGRectGetMaxY(separator.frame) + 20, view.bounds.size.width, view.bounds.size.height/4)];
    UIImageView *tweakIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, maximumImageSize, maximumImageSize)];
    tweakIcon.contentMode = UIViewContentModeScaleAspectFit;
    tweakIcon.tintColor = [Theming getAccentColor];
    UIImage *tweakImage = [UIImage systemImageNamed:@"cube.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:60]];
    tweakIcon.image = tweakImage;
    [tweakOptionContainer addSubview:tweakIcon];

    UIButton *tweakRadioButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tweakRadioButton.frame = CGRectMake(CGRectGetMaxX(tweakIcon.frame) + 10, 10, 30, 30);
    tweakRadioButton.layer.cornerRadius = 15;
    tweakRadioButton.layer.borderWidth = 2;
    tweakRadioButton.layer.borderColor = [Theming getFooterColor].CGColor;
    tweakRadioButton.tag = 2;
    [tweakRadioButton addTarget:self action:@selector(radioButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [tweakOptionContainer addSubview:tweakRadioButton];

    UILabel *tweakLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(tweakRadioButton.frame) + 10, 10, view.bounds.size.width - 160, 30)];
    tweakLabel.text = @"Tweak";
    tweakLabel.textColor = [Theming getWhiteColor];
    tweakLabel.font = [UIFont boldSystemFontOfSize:16];
    [tweakOptionContainer addSubview:tweakLabel];

    UILabel *tweakDescription = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(tweakIcon.frame) + 10, CGRectGetMaxY(tweakLabel.frame) + 10, view.bounds.size.width - 150, view.bounds.size.height/6)];
    tweakDescription.text = @"Recommended for Jailbreak users. This injects Geode directly into Geometry Dash. However, Geode will not appear once you're unjailbroken.\nIt's recommended to install the TrollStore (.tipa) version of this launcher if you plan on using this.";
    tweakDescription.textColor = [Theming getFooterColor];
    tweakDescription.font = [UIFont systemFontOfSize:13];
    tweakDescription.numberOfLines = 7;
    [tweakOptionContainer addSubview:tweakDescription];

    [view addSubview:tweakOptionContainer];
    [self radioButtonTapped:normalRadioButton];

    UIButton *nextButton = [self addNextButton];
    nextButton.frame = CGRectMake(view.center.x - 70, view.bounds.size.height - 120, 140, 45);
    [view addSubview:nextButton];

    [self transitionToView:view];
}

- (void)showLaunchMethodStep {
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Launch Method";
    titleLabel.textColor = [Theming getWhiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:24];
    titleLabel.frame = CGRectMake(0, 80, view.bounds.size.width, 45);
    [view addSubview:titleLabel];

    int maximumImageSize = view.bounds.size.width / 4;

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"You can change this later in the Settings.";
    subtitleLabel.textColor = [Theming getFooterColor];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [UIFont systemFontOfSize:16];
    subtitleLabel.frame = CGRectMake(0, CGRectGetMaxY(titleLabel.frame) + 10, view.bounds.size.width, 30);
    [view addSubview:subtitleLabel];

    UIView *normalOptionContainer = [[UIView alloc] initWithFrame:CGRectMake(25, view.bounds.size.height/4, view.bounds.size.width, view.bounds.size.height/5)];

    UIImageView *normalIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, maximumImageSize, maximumImageSize)];
    normalIcon.contentMode = UIViewContentModeScaleAspectFit;
    normalIcon.tintColor = [Theming getAccentColor];
    UIImage *shieldImage = [UIImage systemImageNamed:@"bolt.slash.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:60]];
    normalIcon.image = shieldImage;
    [normalOptionContainer addSubview:normalIcon];

    UIButton *normalRadioButton = [UIButton buttonWithType:UIButtonTypeCustom];
    normalRadioButton.frame = CGRectMake(CGRectGetMaxX(normalIcon.frame) + 10, 10, 30, 30);
    normalRadioButton.layer.cornerRadius = 15;
    normalRadioButton.layer.borderWidth = 2;
    normalRadioButton.layer.borderColor = [Theming getFooterColor].CGColor;
    normalRadioButton.tag = 3;
    [normalRadioButton addTarget:self action:@selector(radioButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [normalOptionContainer addSubview:normalRadioButton];

    UILabel *normalLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(normalRadioButton.frame) + 10, 10, view.bounds.size.width - 160, 30)];
    normalLabel.text = @"JIT-Less";
    //lock.open
    normalLabel.textColor = [Theming getWhiteColor];
    normalLabel.font = [UIFont boldSystemFontOfSize:16];
    [normalOptionContainer addSubview:normalLabel];

    UILabel *normalDescription = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(normalIcon.frame) + 7, CGRectGetMaxY(normalLabel.frame) + 10, view.bounds.size.width - 150, view.bounds.size.height/8)];
    normalDescription.text = @"This method requires patching AltStore/SideStore, or importing a certificate if you didn't sideload this app with those stores. Note that launching may take longer, and restarting sometimes may not work.";
    normalDescription.textColor = [Theming getFooterColor];
    normalDescription.font = [UIFont systemFontOfSize:13];
    normalDescription.numberOfLines = 5;
    [normalOptionContainer addSubview:normalDescription];

    [view addSubview:normalOptionContainer];

    // =============
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(40, CGRectGetMaxY(normalOptionContainer.frame) + 10, view.bounds.size.width - 80, 1)];
    separator.backgroundColor = [UIColor darkGrayColor];
    [view addSubview:separator];
    // =============

    UIView *tweakOptionContainer = [[UIView alloc] initWithFrame:CGRectMake(25, CGRectGetMaxY(separator.frame) + 20, view.bounds.size.width, view.bounds.size.height/4)];
    UIImageView *tweakIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, maximumImageSize, maximumImageSize)];
    tweakIcon.contentMode = UIViewContentModeScaleAspectFit;
    tweakIcon.tintColor = [Theming getAccentColor];
    UIImage *tweakImage = [UIImage systemImageNamed:@"bolt.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:60]];
    tweakIcon.image = tweakImage;
    [tweakOptionContainer addSubview:tweakIcon];

    UIButton *tweakRadioButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tweakRadioButton.frame = CGRectMake(CGRectGetMaxX(tweakIcon.frame) + 10, 10, 30, 30);
    tweakRadioButton.layer.cornerRadius = 15;
    tweakRadioButton.layer.borderWidth = 2;
    tweakRadioButton.layer.borderColor = [Theming getFooterColor].CGColor;
    tweakRadioButton.tag = 4;
    [tweakRadioButton addTarget:self action:@selector(radioButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [tweakOptionContainer addSubview:tweakRadioButton];

    UILabel *tweakLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(tweakRadioButton.frame) + 10, 10, view.bounds.size.width - 160, 30)];
    tweakLabel.text = @"JIT";
    tweakLabel.textColor = [Theming getWhiteColor];
    tweakLabel.font = [UIFont boldSystemFontOfSize:16];
    [tweakOptionContainer addSubview:tweakLabel];

    UILabel *tweakDescription = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(tweakIcon.frame) + 7, CGRectGetMaxY(tweakLabel.frame) + 10, view.bounds.size.width - 150, view.bounds.size.height/6)];
    tweakDescription.text = @"This method requires you to run Geode with JIT everytime, or use a JITStreamer-EB instance (with Auto JIT or not). This method is more stable, however it requires an internet connection each time you want to launch Geometry Dash.";
    tweakDescription.textColor = [Theming getFooterColor];
    tweakDescription.font = [UIFont systemFontOfSize:13];
    tweakDescription.numberOfLines = 7;
    [tweakOptionContainer addSubview:tweakDescription];

    [view addSubview:tweakOptionContainer];
    [self radioButtonTapped:normalRadioButton];

    UIButton *nextButton = [self addNextButton];
    nextButton.frame = CGRectMake(view.center.x - 70, view.bounds.size.height - 120, 140, 45);
    [view addSubview:nextButton];

    [self transitionToView:view];
}


- (void)radioButtonTapped:(UIButton *)sender {
    for (UIView *subview in sender.superview.superview.subviews) {
        for (UIView *containerView in subview.subviews) {
            if ([containerView isKindOfClass:[UIButton class]] && containerView != sender) {
                [(UIButton *)containerView setBackgroundColor:[UIColor clearColor]];
                [(UIButton *)containerView layer].borderWidth = 2;
            }
        }
    }
    sender.backgroundColor = [Theming getAccentColor];
    sender.layer.borderWidth = 0;
    if (sender.tag == 1) {
        self.installMethod = @"Normal";
    } else if (sender.tag == 2) {
        self.installMethod = @"Tweak";
    } else if (sender.tag == 3) {
        self.useJITLess = YES;
    } else if (sender.tag == 4) {
        self.useJITLess = NO;
    }
}

- (void)showJailbreakStoreStep {
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Choose Jailbreak Store";
    titleLabel.textColor = [Theming getWhiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:28];
    titleLabel.frame = CGRectMake(0, 80, view.bounds.size.width, 30);
    [view addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"If yours isn't listed, you can click the 'Share' button\nto open the repo link.";
    subtitleLabel.numberOfLines = 2;
    subtitleLabel.textColor = [Theming getFooterColor];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [UIFont systemFontOfSize:12];
    subtitleLabel.frame = CGRectMake(0, CGRectGetMaxY(titleLabel.frame) + 15, view.bounds.size.width, 30);
    [view addSubview:subtitleLabel];

    [[Utils getPrefs] setBool:YES forKey:@"USE_TWEAK"];
    NSArray *stores = @[@"Sileo", @"Zebra", @"Cydia"];

    for (NSInteger i = 0; i < stores.count; i++) { //
        int center = view.center.x - 45;
        switch (i) {
            case 0:
                center = center - 110;
                break;
            case 2:
                center = center + 110;
                break;
        }
        UIView *storeOptionContainer = [[UIView alloc] initWithFrame:CGRectMake(center, view.center.y - 100, 90, 200)];

        UIButton *storeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        storeButton.frame = CGRectMake(0, 0, 90, 90);
        storeButton.tag = i;
        [storeButton setBackgroundImage:[UIImage imageNamed:stores[i]] forState:UIControlStateNormal];
        [storeButton addTarget:self action:@selector(storeSelected:) forControlEvents:UIControlEventTouchUpInside];

        UILabel *storeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, 90, 90)];
        storeLabel.text = [NSString stringWithFormat:@"Open in\n%@", stores[i]];
        storeLabel.textColor = [Theming getWhiteColor];
        storeLabel.textAlignment = NSTextAlignmentCenter;
        storeLabel.numberOfLines = 2;
        storeLabel.font = [UIFont systemFontOfSize:16];

        [storeOptionContainer addSubview:storeButton];
        [storeOptionContainer addSubview:storeLabel];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(storeSelected:)];
        storeOptionContainer.tag = i;
        storeOptionContainer.userInteractionEnabled = YES;
        [storeOptionContainer addGestureRecognizer:tapGesture];

        [view addSubview:storeOptionContainer];
    }

    UIButton *nextButton = [self addNextButton];
    nextButton.frame = CGRectMake(view.center.x - 110, view.bounds.size.height - 150, 140, 45);
    [view addSubview:nextButton];

    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeSystem];
    shareButton.frame = CGRectMake(CGRectGetMaxX(nextButton.frame) + 30, view.bounds.size.height - 150, 40, 40);
    UIImage *shareImage = [UIImage systemImageNamed:@"square.and.arrow.up" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20]];
    [shareButton setImage:shareImage forState:UIControlStateNormal];
    shareButton.tintColor = [UIColor systemBlueColor];
    [shareButton addTarget:self action:@selector(otherStoreOption) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:shareButton];

    [self transitionToView:view];
}

- (void)storeSelected:(UIButton*)button {
    //UIView *storeView = gestureRecognizer.view;
    /*NSArray *stores = @[@"Sileo", @"Zebra", @"Cydia"];

    self.selectedStore = stores[storeView.tag];
    storeView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    for (UIView *subview in storeView.superview.subviews) {
        if ([subview isKindOfClass:[UIView class]] && subview != storeView && subview.tag >= 0 && subview.tag < stores.count) {
            subview.backgroundColor = [UIColor clearColor];
        }
    }*/
    // was going to have it selectable to make it look fancy but making it just open sounds easier...
    switch (button.tag) {
        case 0: { // Sileo
            if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"sileo://"]]) return [Utils showError:self title:@"You do not have Sileo installed!" error:nil];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"sileo://source/https://geode-catgirls.github.io/repo"] options:@{} completionHandler:nil];
            break;
        }
        case 1: { // Zebra
            if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"zbra://"]]) return [Utils showError:self title:@"You do not have Zebra installed!" error:nil];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"zbra://sources/add/https://geode-catgirls.github.io/repo"] options:@{} completionHandler:nil];
            break;
        }
        case 2: { // Cydia
            if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cydia://"]]) return [Utils showError:self title:@"You do not have Cydia installed!" error:nil];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://url/https://cydia.saurik.com/api/share#?source=https://geode-catgirls.github.io/repo"] options:@{} completionHandler:nil];
            break;
        }
    }
}

- (void)otherStoreOption {
    /*NSURL *zipFileURL = [NSURL URLWithString:@"https://github.com/geode-catgirls/repo/raw/refs/heads/main/debs/gay.rooot.geodeinject_0.0.2_iphoneos-arm.deb"];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[zipFileURL] applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];
    [self presentViewController:activityVC animated:YES completion:nil];*/ 
    NSURL* url = [NSURL URLWithString:@"https://geode-catgirls.github.io/repo"];
    if([[NSClassFromString(@"UIApplication") sharedApplication] canOpenURL:url]){
        [[NSClassFromString(@"UIApplication") sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void)completeSetup {
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
    if (self.useJITLess) {
        [[Utils getPrefs] setBool:YES forKey:@"JITLESS"];
    }
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Setup complete!";
    titleLabel.textColor = [Theming getWhiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:32];
    titleLabel.frame = CGRectMake(0, view.center.y - 40, view.bounds.size.width, 45);
    [view addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"Click next to start using Geode!";
    subtitleLabel.textColor = [Theming getFooterColor];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [UIFont systemFontOfSize:16];
    subtitleLabel.frame = CGRectMake(0, CGRectGetMaxY(titleLabel.frame) + 10, view.bounds.size.width, 30);
    [view addSubview:subtitleLabel];

    UIButton *nextButton = [self addNextButton];
    [nextButton removeTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
    [nextButton addTarget:self action:@selector(completeSetup2) forControlEvents:UIControlEventTouchUpInside];
    nextButton.frame = CGRectMake(view.center.x - 70, CGRectGetMaxY(subtitleLabel.frame) + 20, 140, 45);
    [view addSubview:nextButton];

    [self transitionToView:view];

    [[Utils getPrefs] setBool:YES forKey:@"CompletedSetup"];
    [[Utils getPrefs] synchronize];
}

- (void)completeSetup2 {
    RootViewController *rootViewController = [[RootViewController alloc] init];
    UIWindowScene *scene = (id)[UIApplication.sharedApplication.connectedScenes allObjects].firstObject;
    UIWindow *window = scene.windows.firstObject;
    [UIView transitionWithView:window duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
        window.rootViewController = rootViewController;
    } completion:nil];
}

#pragma mark - Color stuff

- (void)colorSkipPressed {
    _skipColor = YES;
    [self goToNextStep];
}

- (void)onColorClickButton {
    self.colorSelectionController = [[MSColorSelectionViewController alloc] init];
    UINavigationController *navCtrl = [[UINavigationController alloc] initWithRootViewController:self.colorSelectionController];

    navCtrl.popoverPresentationController.delegate = self;
    navCtrl.modalInPresentation = YES;
    navCtrl.preferredContentSize = [self.colorSelectionController.view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    navCtrl.modalPresentationStyle = UIModalPresentationOverFullScreen;

    self.colorSelectionController.delegate = self;
    self.colorSelectionController.color = [Theming getAccentColor];

    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", ) style:UIBarButtonItemStyleDone target:self action:@selector(ms_dismissViewController:)];
        self.colorSelectionController.navigationItem.rightBarButtonItem = doneBtn;
    }
    [self presentViewController:navCtrl animated:YES completion:nil];
}

- (void)ms_dismissViewController:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)colorViewController:(MSColorSelectionViewController *)colorViewCntroller didChangeColor:(UIColor *)color
{
    _accentColor = color;
    if (self.colorNextButton != nil && self.colorPreviewLabel != nil) {
        self.colorSelectionController.color = color;
        [self.colorNextButton setBackgroundColor:color];
        [self.colorNextButton setTitleColor:[Theming getTextColor:color] forState:UIControlStateNormal];
        [self.colorNextButton setTintColor:[Theming getTextColor:color]];
        self.colorPreviewLabel.textColor = color;
    }
}
@end
