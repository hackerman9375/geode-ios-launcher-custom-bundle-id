#include <UIKit/UIKit.h>
#import "MSColorPicker/MSColorPicker/MSColorSelectionViewController.h"
#import "RootViewController.h"

@interface SettingsVC : UIViewController<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, MSColorSelectionViewControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) RootViewController *root;
@end
