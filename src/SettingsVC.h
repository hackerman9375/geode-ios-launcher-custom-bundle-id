#import "MSColorPicker/MSColorPicker/MSColorSelectionViewController.h"
#import "RootViewController.h"
#include <UIKit/UIKit.h>

@interface SettingsVC
	: UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, MSColorSelectionViewControllerDelegate>
@property(nonatomic, strong) UITableView* tableView;
@property(nonatomic, strong) RootViewController* root;
@end
