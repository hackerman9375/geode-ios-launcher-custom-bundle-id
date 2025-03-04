#include <UIKit/UIKit.h>
#import "MSColorPicker/MSColorPicker/MSColorSelectionViewController.h"

typedef NS_ENUM(NSInteger, InstallStep) {
    InstallStepWelcome,
    InstallStepAccentColor,
    InstallStepInstallMethod,
    InstallStepJailbreakStore,
    InstallStepLaunchMethod,
    InstallStepWarning,
    InstallStepComplete
};

@interface IntroVC : UIViewController<UITextFieldDelegate, UIPopoverPresentationControllerDelegate, MSColorSelectionViewControllerDelegate>
#pragma mark - Temp
@property (nonatomic, strong) UIButton *colorNextButton;
@property (nonatomic, strong) UILabel *colorPreviewLabel;
@property (nonatomic, strong) MSColorSelectionViewController *colorSelectionController;
#pragma mark - Temp
@property (nonatomic, strong) UIColor *accentColor;
@property (nonatomic, assign) BOOL skipColor;
@property (nonatomic, assign) InstallStep currentStep;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSString *installMethod;
@property (nonatomic, strong) NSString *launchMethod;
@end
