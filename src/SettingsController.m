#import "SettingsController.h"
#import "src/GeodeInstaller.h"
#import <UIKit/UIKit.h>
#import "src/LCUtils/Shared.h"
#import "src/Theming.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "Utils.h"
#import "LogsView.h"
#import <sys/utsname.h>

NSString *deviceArchitecture() {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

@interface SettingsController () 
@property (nonatomic, strong) NSArray *creditsArray;
@end

@implementation SettingsController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"Settings"];
    self.creditsArray = @[
        @{ @"name" : @"rooot",   @"url" : @"https://github.com/RoootTheFox" },
        @{ @"name" : @"dankmeme01", @"url" : @"https://github.com/dankmeme01" },
        @{ @"name" : @"Firee", @"url" : @"https://github.com/FireMario211" },
        @{ @"name" : @"ninXout", @"url" : @"https://github.com/ninXout" },
        @{ @"name" : @"Duy Tran Khanh", @"url" : @"https://github.com/khanhduytran0" },
        @{ @"name" : @"camila314", @"url" : @"https://github.com/camila314" },
        @{ @"name" : @"TheSillyDoggo", @"url" : @"https://github.com/TheSillyDoggo" },
        @{ @"name" : @"Nathan", @"url" : @"https://github.com/verygenericname" },
        @{ @"name" : @"LimeGradient", @"url" : @"https://github.com/LimeGradient" },
        @{ @"name" : @"km7dev", @"url" : @"https://github.com/Kingminer7" },
        @{ @"name" : @"Anh", @"url" : @"https://github.com/AnhNguyenlost13" },
        @{ @"name" : @"pengubow", @"url" : @"https://github.com/pengubow" },
    ];

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
        case 2:
            return 5;
        case 1:
            return 2;
        case 4:
            return [self.creditsArray count];
        case 3:
            return 4;
        default:
            return 0;
    }
}

- (UISwitch*)createSwitch:(BOOL)enabled tag:(NSInteger)tag {
    UISwitch *uiSwitch = [[UISwitch alloc] init];
    [uiSwitch setOn:enabled];
    [uiSwitch setTag:tag];
    [uiSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
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
            } else if (indexPath.row == 3) {
                cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
                cellval1.textLabel.text = @"Enable Automatic Updates";
                cellval1.accessoryView = [self createSwitch:[[NSUserDefaults standardUserDefaults] boolForKey:@"UPDATE_AUTOMATICALLY"] tag:0];
                return cellval1;
            } else if (indexPath.row == 4) {
                cell.textLabel.text = @"Check for Updates";
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
                cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
                cellval1.textLabel.text = @"Automatically Launch";
                cellval1.accessoryView = [self createSwitch:[[NSUserDefaults standardUserDefaults] boolForKey:@"LOAD_AUTOMATICALLY"] tag:1];
                return cellval1;
            }
            break;
        case 2: 
            if (indexPath.row == 0) {
                cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
                cellval1.textLabel.text = @"Developer Mode";
                cellval1.accessoryView = [self createSwitch:[[NSUserDefaults standardUserDefaults] boolForKey:@"DEVELOPER_MODE"] tag:2];
                return cellval1;
            } else if (indexPath.row == 1) {
                cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
                cellval1.textLabel.text = @"Run with JIT";
                cellval1.accessoryView = [self createSwitch:[[NSUserDefaults standardUserDefaults] boolForKey:@"USE_JIT"] tag:3];
                return cellval1;
            } else if (indexPath.row == 2) {
                cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
                cellval1.textLabel.text = @"Use Tweak than JIT";
                cellval1.accessoryView = [self createSwitch:[[NSUserDefaults standardUserDefaults] boolForKey:@"USE_TWEAK"] tag:4];
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
                cellval1.detailTextLabel.text = [Utils getGeodeVersion];
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
        case 4: {
            cell.textLabel.text = self.creditsArray[indexPath.row][@"name"];
            cell.textLabel.textColor = [Theming getAccentColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
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
        case 0:
            return [NSString stringWithFormat:@"Current loader version: %@", [Utils getGeodeVersion]];
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
    NSLog(@"godelol s:%ld,%ld",(long)indexPath.section,indexPath.row);
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
                //[[self navigationController] pushViewController:colorSelectionController animated:YES];
                [self presentViewController:navCtrl animated:YES completion:nil];
                break;
            }
            case 1: {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"accentColor"];
                [self.root updateState];
                [self.tableView reloadData];
                break;
            }
            case 2: { // Open file manager
                NSString *openURL = [
                    NSString stringWithFormat:@"shareddocuments://%@",
                    [[LCPath dataPath] URLByAppendingPathComponent:@"GeometryDash/Documents"].path
                ];
                NSURL* url = [NSURL URLWithString:openURL];
                if([[NSClassFromString(@"UIApplication") sharedApplication] canOpenURL:url]){
                    [[NSClassFromString(@"UIApplication") sharedApplication] openURL:url options:@{} completionHandler:nil];
                }
                //[[LSApplicationWorkspace defaultWorkspace] openApplicationWithBundleID:@"com.apple.DocumentsApp"];
                break;
            }
            case 4: { // Check for updates
                [[GeodeInstaller alloc] checkUpdates:_root download:YES];
                break;
            }
            default:
                break;
        }
    } else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0: { // Safe Mode
                break;
            }
        }
    } else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 3: // View app logs
                [[self navigationController] pushViewController:
                    [[LogsViewController alloc] initWithFile:[Utils pathToMostRecentLogInDirectory:[[LCPath dataPath] URLByAppendingPathComponent:@"GeometryDash/Documents/game/geode/logs/"].path]]
                    animated:YES
                ];
                break;
            case 4: // View recent crash
                //[Utils toggleKey:@"LOAD_AUTOMATICALLY"];
                break;
        }
    } else if (indexPath.section == 4) {
        NSURL* url = [NSURL URLWithString:self.creditsArray[indexPath.row][@"url"]];
        if([[NSClassFromString(@"UIApplication") sharedApplication] canOpenURL:url]){
            [[NSClassFromString(@"UIApplication") sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// ios 13 bad!
- (void)switchValueChanged:(UISwitch *)sender {
    switch (sender.tag) {
        case 0: // Enable Automatic Updates
            [Utils toggleKey:@"UPDATE_AUTOMATICALLY"];
            break;
        case 1: // Automatically Launch
            [Utils toggleKey:@"LOAD_AUTOMATICALLY"];
            break;
        case 2: // Dev Mode
            [Utils toggleKey:@"DEVELOPER_MODE"];
            break;
        case 3: // Run With JIT
            //[Utils toggleKey:@"USE_JIT"];
            break;
        case 4: // Use Tweak instead of JIT
            //[Utils toggleKey:@"USE_TWEAK"];
            break;
    }
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
