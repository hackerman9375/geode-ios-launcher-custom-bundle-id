#import "SettingsController.h"
#import <UIKit/UIKit.h>
#import "src/LCUtils/Shared.h"
#import "src/Theming.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "Utils.h"
#import <sys/utsname.h>

NSString *deviceArchitecture() {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

@implementation SettingsController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"Settings"];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    [[self tableView] setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[self tableView] setDelegate:self];
    [[self tableView] setDataSource:self];
    [[self view] addSubview:self.tableView];
    //https://github.com/reactwg/react-native-new-architecture/blob/76d8426c27c1bf30c235f653e425ef872554a33b/docs/fabric-native-components.md
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [[self view] setBackgroundColor:[Theming getBackgroundColor]];
    [[[self navigationController] navigationBar] setPrefersLargeTitles:YES];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
        case 0:
            return 3;
        case 1:
            return 2;
        case 2:
            return 5;
        case 3:
            return 4;
        case 4:
            return 1;
        default:
            return 0;
    }
}

- (UISwitch*)createSwitch:(BOOL)enabled {
    UISwitch *uiSwitch = [[UISwitch alloc] init];
    [uiSwitch setOn:enabled];
    return uiSwitch;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    UITableViewCell *cellval1 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    // i wish i could case(0,0) :(
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Accent Color";
                UIView* colView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
                colView.backgroundColor = [Theming getAccentColor];
                colView.layer.cornerRadius = colView.frame.size.width / 2;
                cell.accessoryView = colView;
            } else if (indexPath.row == 1) {
                cell.textLabel.text = @"Reset Accent Color";
                cell.textLabel.textColor = [Theming getAccentColor];
                cell.accessoryType = UITableViewCellAccessoryNone;
            } else if (indexPath.row == 2) {
                cell.textLabel.text = @"Open File Manager";
                cell.textLabel.textColor = [Theming getAccentColor];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
        case 1:
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Launch in Safe Mode";
                cell.textLabel.textColor = [Theming getAccentColor];
                cell.accessoryType = UITableViewCellAccessoryNone;
            } else if (indexPath.row == 1) {
                cellval1.textLabel.text = @"Automatically Launch";
                cellval1.accessoryView = [self createSwitch:YES];
                return cellval1;
            }
            break;
        case 2: 
            if (indexPath.row == 0) {
                cellval1.textLabel.text = @"Developer Mode";
                cellval1.accessoryView = [self createSwitch:YES];
                return cellval1;
            } else if (indexPath.row == 1) {
                cellval1.textLabel.text = @"Run with JIT";
                cellval1.accessoryView = [self createSwitch:YES];
                return cellval1;
            } else if (indexPath.row == 2) {
                cellval1.textLabel.text = @"Use Tweak than JIT";
                cellval1.accessoryView = [self createSwitch:YES];
                return cellval1;
            } else if (indexPath.row == 3) {
                cell.textLabel.text = @"View Application Logs";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else if (indexPath.row == 4) {
                cell.textLabel.text = @"View Recent Crash";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
        case 3: {
            cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
            if (indexPath.row == 0) {
                cellval1.textLabel.text = @"iOS Launcher";
                cellval1.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            } else if (indexPath.row == 1) {
                cellval1.textLabel.text = @"Geode";
                cellval1.detailTextLabel.text = @"UNKNOWN";
            } else if (indexPath.row == 2) {
                NSString *infoPlistPath = [[[LCPath bundlePath] URLByAppendingPathComponent:[Utils gdBundleName]] URLByAppendingPathComponent:@"Info.plist"].path;
                NSDictionary *infoDictionary = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
                cellval1.textLabel.text = @"Geometry Dash";
                cellval1.detailTextLabel.text = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
            } else if (indexPath.row == 3) {
                cellval1.textLabel.text = @"Device";
                NSString *model = [[UIDevice currentDevice] localizedModel];
                NSString *systemName = [[UIDevice currentDevice] systemName];
                NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
                cellval1.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ (%@,%@)", systemName,
                   systemVersion,
                   model,
                   [Utils archName]
                ];
            }
            return cellval1;
        }
    }

	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"General";
        case 1:
            return @"Gameplay";
        case 2:
            return @"Advanced";
        case 3:
            return @"About";
        case 4:
            return @"Credits";
        default:
            return @"Unknown";
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 1:
            return @"Launches the game after a short delay.";
        case 4:
            return @"Thanks to these contributors who helped contribute towards making Geode on iOS a possibility!";
        default:
            return nil;
    }
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0: { // Change accent color
                MSColorSelectionViewController *colorSelectionController = [[MSColorSelectionViewController alloc] init];
                UINavigationController *navCtrl = [[UINavigationController alloc] initWithRootViewController:colorSelectionController];

                navCtrl.modalPresentationStyle = UIModalPresentationPopover;
                navCtrl.popoverPresentationController.delegate = self;
                navCtrl.preferredContentSize = [colorSelectionController.view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
                navCtrl.modalPresentationStyle = UIModalPresentationOverFullScreen;

                colorSelectionController.delegate = self;
                colorSelectionController.color = [Theming getAccentColor];

                if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
                    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", ) style:UIBarButtonItemStyleDone target:self action:@selector(ms_dismissViewController:)];
                    colorSelectionController.navigationItem.rightBarButtonItem = doneBtn;
                }

                [self presentViewController:navCtrl animated:YES completion:nil];


                break;
            }
            case 1: {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"accentColor"];
                [[NSUserDefaults standardUserDefaults] synchronize]; 
                [self.root updateState];
                [self.tableView reloadData];
                break;
            }
            case 2: { // Open file manager
                NSString *openURL = [
                    NSString stringWithFormat:@"shareddocuments://%@",
                    [LCPath docPath].path
                ];
                NSURL* url = [NSURL URLWithString:openURL];
                if([[NSClassFromString(@"UIApplication") sharedApplication] canOpenURL:url]){
                    [[NSClassFromString(@"UIApplication") sharedApplication] openURL:url options:@{} completionHandler:nil];
                    return;
                }
                //[[LSApplicationWorkspace defaultWorkspace] openApplicationWithBundleID:@"com.apple.DocumentsApp"];
                break;
            }
            default:
                break;
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)ms_dismissViewController:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MSColorViewDelegate

- (void)colorViewController:(MSColorSelectionViewController *)colorViewCntroller didChangeColor:(UIColor *)color
{
    [Theming saveAccentColor:color];
    [self.root updateState];
    [self.tableView reloadData];
    //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

@end
