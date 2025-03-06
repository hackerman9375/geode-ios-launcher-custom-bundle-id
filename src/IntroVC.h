#include <UIKit/UIKit.h>
#import "MSColorPicker/MSColorPicker/MSColorSelectionViewController.h"

typedef NS_ENUM(NSInteger, InstallStep) {
    InstallStepWelcome,
    InstallStepAccentColor,
    InstallStepInstallMethod,
    InstallStepJailbreakStore,
    InstallStepWarning,
    InstallStepLaunchMethod,
    InstallStepComplete
};

@interface IntroVC : UIViewController<UITextFieldDelegate, UIPopoverPresentationControllerDelegate, MSColorSelectionViewControllerDelegate>
#pragma mark - Color Temp
@property (nonatomic, strong) UIButton *colorNextButton;
@property (nonatomic, strong) UILabel *colorPreviewLabel;
@property (nonatomic, strong) MSColorSelectionViewController *colorSelectionController;
#pragma mark - Other
@property (nonatomic, strong) UIColor *accentColor;
@property (nonatomic, assign) BOOL skipColor;
@property (nonatomic, assign) InstallStep currentStep;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSString *installMethod;
@property (nonatomic, assign) BOOL useJITLess;
@end
