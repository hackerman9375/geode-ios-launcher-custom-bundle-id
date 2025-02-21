#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController
// ok listen, i just want performance
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *projectLabel;
@property (nonatomic, strong) UILabel *optionalTextLabel;
@property (nonatomic, strong) UIButton *launchButton;
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIButton *infoButton;
@end
