#import "GeodeInstaller.h"
#import "LogsView.h"
#import "SettingsVC.h"
#import "VerifyInstall.h"
#import "components/LogUtils.h"
#import "src/LCUtils/LCUtils.h"
#import "src/LCUtils/Shared.h"
#import "src/Theming.h"
#import "src/Utils.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include <dlfcn.h>
#include <spawn.h>

@interface SettingsVC () <UIDocumentPickerDelegate>
@property(nonatomic, strong) NSArray* creditsArray;
@end

@implementation SettingsVC
- (void)viewDidLoad {
	[super viewDidLoad];
	[self setTitle:@"Settings"];
	self.creditsArray = @[
		@{ @"name" : @"rooot", @"url" : @"https://github.com/RoootTheFox" },
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
	// https://github.com/reactwg/react-native-new-architecture/blob/76d8426c27c1bf30c235f653e425ef872554a33b/docs/fabric-native-components.md
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

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return [[Utils getPrefs] boolForKey:@"DEVELOPER_MODE"] ? 8 : 7;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
	case 0:
	case 4:
		return 5;
	case 1:
	case 5:
		return 4;
	case 2:
		return 2;
	case 3:
		// return 6;
		return 0;
	case 6:
		return [self.creditsArray count];
	case 7:
		return 5;
	default:
		return 0;
	}
}

- (UISwitch*)createSwitch:(BOOL)enabled tag:(NSInteger)tag disable:(BOOL)disable {
	UISwitch* uiSwitch = [[UISwitch alloc] init];
	[uiSwitch setOn:enabled];
	[uiSwitch setTag:tag];
	[uiSwitch setEnabled:!disable];
	[uiSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
	return uiSwitch;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	UITableViewCell* cellval1 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
	// i wish i could case(0,0) :(
	switch (indexPath.section) {
	case 0:
		if (indexPath.row == 0) {
			cell.textLabel.text = @"general.accent-color".loc;
			UIView* colView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
			colView.backgroundColor = [Theming getAccentColor];
			colView.layer.cornerRadius = colView.frame.size.width / 2;
			cell.accessoryView = colView;
		} else if (indexPath.row == 1) {
			cell.textLabel.text = @"general.reset-accent-color".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 2) {
			cell.textLabel.text = @"general.open-fm".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 3) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"general.enable-updates".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"UPDATE_AUTOMATICALLY"] tag:0 disable:NO];
			return cellval1;
		} else if (indexPath.row == 4) {
			cell.textLabel.text = @"general.check-updates".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		break;
	case 1:
		if (indexPath.row == 0) {
			cell.textLabel.text = @"gameplay.safe-mode".loc;
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 1) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"gameplay.auto-launch".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"LOAD_AUTOMATICALLY"] tag:1 disable:NO];
			return cellval1;
		} else if (indexPath.row == 2) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"gameplay.fix-rotation".loc;
			if ([[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
				cellval1.textLabel.textColor = [UIColor systemGrayColor];
			}
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"FIX_ROTATION"] tag:5 disable:[[Utils getPrefs] boolForKey:@"USE_TWEAK"]];
			return cellval1;
		}
		if (indexPath.row == 3) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"gameplay.fix-black-screen".loc;
			if ([[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
				cellval1.textLabel.textColor = [UIColor systemGrayColor];
			}
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"FIX_BLACKSCREEN"] tag:8 disable:[[Utils getPrefs] boolForKey:@"USE_TWEAK"]];
			return cellval1;
		}
		break;
	case 2: {
		if (indexPath.row == 0) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"jit.enable-auto-jit".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"AUTO_JIT"] tag:4 disable:NO];
			return cellval1;
		} else if (indexPath.row == 1) {
			UITextField* textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
			textField.textAlignment = NSTextAlignmentRight;
			textField.delegate = self;
			textField.returnKeyType = UIReturnKeyDone;
			textField.autocorrectionType = UITextAutocorrectionTypeNo;
			textField.keyboardType = UIKeyboardTypeURL;
			textField.tag = 0;
			cell.accessoryView = textField;
			cell.textLabel.text = @"jit.auto-jit-server".loc;
			textField.placeholder = @"http://x.x.x.x:9172";
			textField.text = [[Utils getPrefs] stringForKey:@"SideJITServerAddr"];
		}
		break;
	}
	case 3: {
		if (indexPath.row == 0) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"Enable JIT-Less";
			if (![Utils isSandboxed]) {
				cellval1.textLabel.textColor = [UIColor systemGrayColor];
			}
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"JITLESS"] tag:9 disable:![Utils isSandboxed]];
			return cellval1;
		} else if (indexPath.row == 1) {
			cell.textLabel.text = [NSString stringWithFormat:@"Patch %@", [LCUtils getStoreName]];
			if (![LCUtils isAppGroupAltStoreLike]) {
				cell.textLabel.textColor = [UIColor systemGrayColor];
			} else {
				cell.textLabel.textColor = [Theming getAccentColor];
			}
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 2) {
			if ([[Utils getPrefs] boolForKey:@"LCCertificateImported"]) {
				cell.textLabel.text = @"Remove Certificate";
			} else {
				cell.textLabel.text = @"Import Certificate";
			}
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
			if ([LCUtils isAppGroupAltStoreLike]) {
				cellval1.textLabel.textColor = [UIColor systemGrayColor];
			}
		} else if (indexPath.row == 3) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"Use ZSign";
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"USE_ZSIGN"] tag:10 disable:NO];
			return cellval1;
		} else if (indexPath.row == 4) {
			cell.textLabel.text = @"Test JIT-Less Mode";
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 5) {
			cell.textLabel.text = @"Force Resign";
			if (![[Utils getPrefs] boolForKey:@"JITLESS"]) {
				cell.textLabel.textColor = [UIColor systemGrayColor];
			} else {
				cell.textLabel.textColor = [Theming getAccentColor];
			}
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		break;
	}
	case 4:
		if (indexPath.row == 0) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"advanced.dev-mode".loc;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"DEVELOPER_MODE"] tag:2 disable:NO];
			return cellval1;
		} else if (indexPath.row == 1) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			if (![Utils isJailbroken]) {
				cellval1.textLabel.textColor = [UIColor systemGrayColor];
			}
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"USE_TWEAK"] tag:3 disable:![Utils isJailbroken]];
			cellval1.textLabel.text = @"advanced.use-tweak".loc;
			return cellval1;
		} else if (indexPath.row == 2) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"MANUAL_REOPEN"] tag:7 disable:[[Utils getPrefs] boolForKey:@"USE_TWEAK"]];
			cellval1.textLabel.text = @"advanced.manual-reopen-jit".loc;
			if ([[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
				cellval1.textLabel.textColor = [UIColor systemGrayColor];
			}
			return cellval1;
		} else if (indexPath.row == 3) {
			cell.textLabel.text = @"advanced.view-recent-logs".loc;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else if (indexPath.row == 4) {
			cell.textLabel.text = @"advanced.view-recent-crash".loc;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		break;
	case 5: {
		cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
		if (indexPath.row == 0) {
			cellval1.textLabel.text = @"about.launcher".loc;
			cellval1.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
		} else if (indexPath.row == 1) {
			cellval1.textLabel.text = @"about.geode".loc;
			cellval1.detailTextLabel.text = [Utils getGeodeVersion];
		} else if (indexPath.row == 2) {
			NSString* infoPlistPath;
			if ([[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
				infoPlistPath = [[Utils getGDBundlePath] stringByAppendingPathComponent:@"GeometryJump.app/Info.plist"];
			} else {
				infoPlistPath = [[[LCPath bundlePath] URLByAppendingPathComponent:[Utils gdBundleName]] URLByAppendingPathComponent:@"Info.plist"].path;
			}
			NSDictionary* infoDictionary = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
			cellval1.textLabel.text = @"about.geometry-dash".loc;
			cellval1.detailTextLabel.text = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
		} else if (indexPath.row == 3) {
			cellval1.textLabel.text = @"about.device".loc;
			NSString* model = [[UIDevice currentDevice] localizedModel];
			NSString* systemName = [[UIDevice currentDevice] systemName];
			NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
			cellval1.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ (%@,%@)", systemName, systemVersion, model, [Utils archName]];
		}
		return cellval1;
	}
	case 6: {
		cell.textLabel.text = self.creditsArray[indexPath.row][@"name"];
		cell.textLabel.textColor = [Theming getAccentColor];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	}
	case 7: {
		if (indexPath.row == 0) {
			cell.textLabel.text = @"advanced.view-app-logs".loc;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else if (indexPath.row == 1) {
			UITextField* textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
			textField.textAlignment = NSTextAlignmentRight;
			textField.delegate = self;
			textField.returnKeyType = UIReturnKeyDone;
			textField.autocorrectionType = UITextAutocorrectionTypeNo;
			textField.keyboardType = UIKeyboardTypeURL;
			textField.tag = 2;
			cell.accessoryView = textField;
			cell.textLabel.text = @"Reinstall Addr";
			textField.placeholder = @"http://x.x.x.x:3000";
			textField.text = [[Utils getPrefs] stringForKey:@"DEV_REINSTALL_ADDR"];
		} else if (indexPath.row == 2) {
			cell.textLabel.text = @"TrollStore App Reinstall";
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else if (indexPath.row == 3) {
			cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
			cellval1.textLabel.text = @"Completed Setup";
			cellval1.accessoryView = [self createSwitch:[[Utils getPrefs] boolForKey:@"CompletedSetup"] tag:6 disable:NO];
			return cellval1;
		} else if (indexPath.row == 4) {
			cell.textLabel.text = @"Test GD Bundle Access";
			cell.textLabel.textColor = [Theming getAccentColor];
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		break;
	}
	}

	return cell;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
	return NO;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	[tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
	case 0:
		return @"general".loc;
	case 1:
		return @"gameplay".loc;
	case 2:
		return @"jit".loc;
	case 3:
		return @"JIT-Less (Disabled)";
	case 4:
		return @"advanced".loc;
	case 5:
		return @"about".loc;
	case 6:
		return @"credits".loc;
	case 7:
		return @"developer".loc;
	default:
		return @"Unknown";
	}
}

- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section {
	switch (section) {
	case 0:
		return [@"general.footer" localizeWithFormat:[Utils getGeodeVersion]];
	case 1:
		return @"gameplay.footer".loc;
	case 2:
		return @"jit.footer".loc;
	// case 3:
	// return @"jitless.footer".loc;
	case 6:
		return @"credits.footer".loc;
	default:
		return nil;
	}
}

- (void)patchAltstore:(BOOL)archive {
	NSError* err;
	NSURL* altStoreIpa = [LCUtils archiveTweakedAltStoreWithError:&err];
	if (altStoreIpa == nil || err)
		return [Utils showError:self title:@"Failed to retrieve tweaked store" error:err];
	NSURL* storeInstallUrl = [NSURL URLWithString:[NSString stringWithFormat:[LCUtils storeInstallURLScheme], altStoreIpa]];
	if (archive) {
		[[NSFileManager defaultManager] moveItemAtURL:altStoreIpa
												toURL:[[LCPath docPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"Patched%@.ipa", [LCUtils getStoreName]]]
												error:&err];
		if (err)
			return [Utils showError:self title:@"Failed to move patched store" error:err];
		[Utils showNotice:self title:[NSString stringWithFormat:@"Patched %@ has been saved to Geode's document folder. Please sideload it.", [LCUtils getStoreName]]];
	} else {
		[[UIApplication sharedApplication] openURL:storeInstallUrl options:@{} completionHandler:nil];
	}
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	if (indexPath.section == 0) {
		switch (indexPath.row) {
		case 0: { // Change accent color
			MSColorSelectionViewController* colorSelectionController = [[MSColorSelectionViewController alloc] init];
			UINavigationController* navCtrl = [[UINavigationController alloc] initWithRootViewController:colorSelectionController];

			navCtrl.popoverPresentationController.delegate = self;
			navCtrl.modalInPresentation = YES;
			navCtrl.preferredContentSize = [colorSelectionController.view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
			navCtrl.modalPresentationStyle = UIModalPresentationOverFullScreen;

			colorSelectionController.delegate = self;
			colorSelectionController.color = [Theming getAccentColor];

			if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
				UIBarButtonItem* doneBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"color.done".loc, ) style:UIBarButtonItemStyleDone target:self
																		   action:@selector(ms_dismissViewController:)];
				colorSelectionController.navigationItem.rightBarButtonItem = doneBtn;
			}
			//[[self navigationController] pushViewController:colorSelectionController animated:YES];
			[self presentViewController:navCtrl animated:YES completion:nil];
			break;
		}
		case 1: {
			[[Utils getPrefs] removeObjectForKey:@"accentColor"];
			[self.root updateState];
			[self.tableView reloadData];
			break;
		}
		case 2: { // Open file manager
			NSString* openURL;
			if ([[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
				openURL = [NSString stringWithFormat:@"filza://%@", [[Utils getGDDocPath] stringByAppendingPathComponent:@"Documents"]];
			} else {
				openURL = [NSString stringWithFormat:@"shareddocuments://%@", [[LCPath dataPath] URLByAppendingPathComponent:@"GeometryDash/Documents"].path];
			}
			NSURL* url = [NSURL URLWithString:openURL];
			if ([[UIApplication sharedApplication] canOpenURL:url]) {
				[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
			}
			break;
		}
		case 4: { // Check for updates
			if ([VerifyInstall verifyGeodeInstalled]) {
				[[GeodeInstaller alloc] checkUpdates:_root download:YES];
				[self dismissViewControllerAnimated:YES completion:nil];
			} else {
				[Utils showError:_root title:@"general.check-updates.error".loc error:nil];
			}
			break;
		}
		default:
			break;
		}
	} else if (indexPath.section == 1) {
		switch (indexPath.row) {
		case 0: { // Safe Mode
			if ([[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
				[Utils tweakLaunch_withSafeMode:true];
				break;
			}
			if ([[Utils getPrefs] boolForKey:@"MANUAL_REOPEN"]) {
				[[Utils getPrefs] setValue:[Utils gdBundleName] forKey:@"selected"];
				[[Utils getPrefs] setValue:@"GeometryDash" forKey:@"selectedContainer"];
				[[Utils getPrefs] setBool:YES forKey:@"safemode"];
				NSFileManager* fm = [NSFileManager defaultManager];
				[fm createFileAtPath:[[LCPath docPath] URLByAppendingPathComponent:@"jitflag"].path contents:[[NSData alloc] init] attributes:@{}];
				[Utils showNotice:self title:@"launcher.relaunch-notice".loc];
			} else {
				NSString* openURL = @"geode://safe-mode";
				NSURL* url = [NSURL URLWithString:openURL];
				if ([[UIApplication sharedApplication] canOpenURL:url]) {
					[_root.launchButton setEnabled:NO];
					[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
					[self dismissViewControllerAnimated:YES completion:nil];
				}
			}
			break;
		}
		}
	} else if (indexPath.section == 3) {
		NSFileManager* fm = [NSFileManager defaultManager];
		switch (indexPath.row) {
		case 1: { // Patch
			if (![LCUtils isAppGroupAltStoreLike])
				break;
			NSString* storeName = [LCUtils getStoreName];
			BOOL isSideStore = [LCUtils store] == SideStore;
			NSString* message;
			if (isSideStore) {
				message = [NSString stringWithFormat:@"To use JIT-Less mode with %@, you must patch %@ in order to retrieve certificate. %@'s functions will not be affected. "
													 @"Please confirm that you can refresh %@ before applying the patch. Continue? (You will need to wait)\n\nIf you have multiple "
													 @"of %@ installed, please select \"Archive Only\" and install the tweaked IPA manually.",
													 storeName, storeName, storeName, storeName, storeName];
			} else {
				message = [NSString stringWithFormat:@"To use JIT-Less mode with %@, you must patch %@ in order to retrieve certificate. %@'s functions will not be affected. "
													 @"Please confirm that you can refresh %@ before applying the patch. Continue? (You will need to wait)",
													 storeName, storeName, storeName, storeName];
			}
			UIAlertController* alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Patch %@", storeName] message:message
																	preferredStyle:UIAlertControllerStyleAlert];

			UIAlertAction* continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDestructive
																   handler:^(UIAlertAction* _Nonnull action) { [self patchAltstore:NO]; }];
			UIAlertAction* archiveAction = [UIAlertAction actionWithTitle:@"Archive Only" style:UIAlertActionStyleDefault
																  handler:^(UIAlertAction* _Nonnull action) { [self patchAltstore:YES]; }];
			UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
			[alert addAction:continueAction];
			if (isSideStore) {
				[alert addAction:archiveAction];
			}
			[alert addAction:cancelAction];
			[self presentViewController:alert animated:YES completion:nil];
			break;
		}
		case 2: { // Import Cert
			// if ([LCUtils isAppGroupAltStoreLike]) break;
			if ([[Utils getPrefs] boolForKey:@"LCCertificateImported"]) {
				UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Warning" message:@"Are you sure you want to remove your certificate?"
																		preferredStyle:UIAlertControllerStyleAlert];
				UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* _Nonnull action) {
					NSUserDefaults* NSUD = [Utils getPrefs];
					[NSUD setObject:nil forKey:@"LCCertificatePassword"];
					[NSUD setObject:nil forKey:@"LCCertificateData"];
					[NSUD setObject:nil forKey:@"LCCertificateTeamId"];
					[NSUD setBool:NO forKey:@"LCCertificateImported"];
					[fm removeItemAtURL:[[LCPath docPath] URLByAppendingPathComponent:@"embedded.mobileprovision"] error:nil];
					[self.tableView reloadData];
					[Utils showNotice:self title:@"Certificate removed."];
				}];
				UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
				[alert addAction:okAction];
				[alert addAction:cancelAction];
				[self presentViewController:alert animated:YES completion:nil];
				break;
			}
			// https://developer.apple.com/documentation/uniformtypeidentifiers/uttype-swift.struct/pkcs12
			// public.x509-certificate
			UTType* type = [UTType typeWithIdentifier:@"com.rsa.pkcs-12"];
			UTType* type2 = [UTType typeWithIdentifier:@"com.apple.mobileprovision"];
			UIDocumentPickerViewController* picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[ type, type2 ] asCopy:YES];
			picker.delegate = self;
			picker.allowsMultipleSelection = YES;
			[self presentViewController:picker animated:YES completion:nil];
			break;
		}
		case 4: { // Test JIT-Less
			if (![LCUtils isAppGroupAltStoreLike] && ![[Utils getPrefs] boolForKey:@"LCCertificateImported"]) {
				[Utils showError:self title:@"You did not sideload this app with AltStore or SideStore! Or you didn't import a certificate." error:nil];
				break;
			}
			NSURL* appGroupURL = [LCUtils appGroupPath];
			if (!appGroupURL)
				break;
			NSURL* patchPath;
			if ([LCUtils store] == AltStore) {
				patchPath = [appGroupURL URLByAppendingPathComponent:@"Apps/com.rileytestut.AltStore/App.app/Frameworks/AltStoreTweak.dylib"];
			} else {
				patchPath = [appGroupURL URLByAppendingPathComponent:@"Apps/com.SideStore.SideStore/App.app/Frameworks/AltStoreTweak.dylib"];
			}
			if (![fm fileExistsAtPath:patchPath.path] && ![[Utils getPrefs] boolForKey:@"LCCertificateImported"]) {
				[Utils showError:self title:@"You must patch before testing JIT-Less mode." error:nil];
				break;
			}
			[LCUtils validateJITLessSetupWithSigner:([[Utils getPrefs] boolForKey:@"USE_ZSIGN"] ? 1 : 0) completionHandler:^(BOOL success, NSError* error) {
				if (success) {
					return [Utils showNotice:self
									   title:[NSString stringWithFormat:@"JIT-Less Mode Test Passed!\nApp Group ID: %@\nStore: %@", [LCUtils appGroupID], [LCUtils getStoreName]]];
				} else {
					AppLog(@"[Geode] JIT-Less test failed: %@", error);
					return [Utils showError:self
									  title:[NSString stringWithFormat:@"The test library has failed to load. This means your certificate may be having issue. Please try to: 1. "
																	   @"Reopen %@; 2. Refresh all apps in %@; 3. Re-patch %@ and try again.\n\nIf you imported certificate, "
																	   @"please ensure the certificate is valid, and it is NOT an enterprise certificate.",
																	   [LCUtils getStoreName], [LCUtils getStoreName], [LCUtils getStoreName]]
									  error:nil];
				}
			}];
			break;
		}
		case 5: { // Force Resign
			if (![[Utils getPrefs] boolForKey:@"JITLESS"])
				break;
			return [_root signApp:YES completionHandler:^(BOOL success, NSString* error) {
				dispatch_async(dispatch_get_main_queue(), ^{
					if (!success) {
						[Utils showError:self title:error error:nil];
					} else {
						[Utils showNotice:self title:@"Resign successful!"];
					}
					[tableView deselectRowAtIndexPath:indexPath animated:YES];
				});
			}];
		}
		}
	} else if (indexPath.section == 4) {
		switch (indexPath.row) {
		case 3: { // View app logs
			NSURL* file = [Utils pathToMostRecentLogInDirectory:[[LCPath dataPath] URLByAppendingPathComponent:@"GeometryDash/Documents/game/geode/logs/"].path];
			if ([[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
				file = [Utils pathToMostRecentLogInDirectory:[[Utils getGDDocPath] stringByAppendingString:@"Documents/game/geode/logs/"]];
			}
			[[self navigationController] pushViewController:[[LogsViewController alloc] initWithFile:file] animated:YES];
			break;
		}
		case 4: { // View recent crash
			NSURL* file = [Utils pathToMostRecentLogInDirectory:[[LCPath dataPath] URLByAppendingPathComponent:@"GeometryDash/Documents/game/geode/crashlogs/"].path];
			if ([[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
				file = [Utils pathToMostRecentLogInDirectory:[[Utils getGDDocPath] stringByAppendingString:@"Documents/game/geode/crashlogs/"]];
			}
			[[self navigationController] pushViewController:[[LogsViewController alloc] initWithFile:file] animated:YES];
			break;
		}
		}
	} else if (indexPath.section == 6) {
		NSURL* url = [NSURL URLWithString:self.creditsArray[indexPath.row][@"url"]];
		if ([[NSClassFromString(@"UIApplication") sharedApplication] canOpenURL:url]) {
			[[NSClassFromString(@"UIApplication") sharedApplication] openURL:url options:@{} completionHandler:nil];
		}
	} else if (indexPath.section == 7) {
		switch (indexPath.row) {
		case 0: { // View Recent App Logs
			[[self navigationController] pushViewController:[[LogsViewController alloc] initWithFile:[[LCPath docPath] URLByAppendingPathComponent:@"app.log"]] animated:YES];
			break;
		}
		case 2: { // TS App Reinstall
			NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"apple-magnifier://install?url=%@", [[Utils getPrefs] stringForKey:@"DEV_REINSTALL_ADDR"]]];
			if ([[NSClassFromString(@"UIApplication") sharedApplication] canOpenURL:url]) {
				[[NSClassFromString(@"UIApplication") sharedApplication] openURL:url options:@{} completionHandler:nil];
			}
			break;
		}
		case 4: { // Bundle Path
			[Utils showNotice:self title:[Utils getGDDocPath]];
			/*NSString *executablePath = [Utils getGDBinaryPath];
			char *const argv[] = {(char *)[executablePath UTF8String], NULL};
			char *const envp[] = {
				"LAUNCHARGS=--geode:safe-mode",
				NULL
			};

			pid_t pid;
			int status = posix_spawn(&pid, [executablePath UTF8String], NULL, NULL, argv, envp);
			if (status == 0) {
				waitpid(pid, NULL, 0);
			}*/
			/*pid_t pid;
			int status;

			posix_spawnattr_t attr;
			posix_spawnattr_init(&attr);

			posix_spawnattr_setflags(&attr, POSIX_SPAWN_START_SUSPENDED);

			int spawnError = posix_spawn(&pid, [executablePath UTF8String], NULL, &attr, argv, NULL);
			posix_spawnattr_destroy(&attr);
			AppLog(@"launching %@", executablePath);
			if (spawnError != 0) {
				AppLog(@"posix_spawn failed: %s", strerror(spawnError));
				return;
			}
			kill(pid, SIGCONT);
			if (waitpid(pid, &status, 0) != -1) {
				AppLog(@"Failed to find process");
			} else {
				AppLog(@"waitpid failed: %s", strerror(errno));
			}*/
			break;
		}
		}
	}

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// ios 13 bad!
- (void)switchValueChanged:(UISwitch*)sender {
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
	case 3: // Use Tweak instead of JIT
		if ([sender isOn]) {
			[Utils showNotice:self title:@"advanced.use-tweak.warning".loc];
		}
		[self.tableView reloadData];
		[Utils toggleKey:@"USE_TWEAK"];
		break;
	case 4: // Auto JIT
		[Utils toggleKey:@"AUTO_JIT"];
		break;
	case 5: // Rotate Fix
		[Utils toggleKey:@"FIX_ROTATION"];
		break;
	case 6: // Completed Setup
		[Utils toggleKey:@"CompletedSetup"];
		break;
	case 7:
		[Utils toggleKey:@"MANUAL_REOPEN"];
		break;
	case 8:
		[Utils toggleKey:@"FIX_BLACKSCREEN"];
		break;
	case 9:
		[Utils toggleKey:@"JITLESS"];
		[self.tableView reloadData];
		break;
	case 10:
		[Utils toggleKey:@"USE_ZSIGN"];
		break;
	}
}

#pragma mark - Text Field Delegate
- (void)textFieldDidEndEditing:(UITextField*)textField {
	switch (textField.tag) {
	case 0: // address
		[[Utils getPrefs] setValue:textField.text forKey:@"SideJITServerAddr"];
		break;
	case 1: // udid
		[[Utils getPrefs] setValue:textField.text forKey:@"JITDeviceUDID"];
		break;
	case 2: // reinstall addr
		[[Utils getPrefs] setValue:textField.text forKey:@"DEV_REINSTALL_ADDR"];
		break;
	}
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)ms_dismissViewController:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MSColorViewDelegate

- (void)colorViewController:(MSColorSelectionViewController*)colorViewCntroller didChangeColor:(UIColor*)color {
	[Theming saveAccentColor:color];
	[self.root updateState];
	[self.tableView reloadData];
	//[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Document Delegate Funcs (for importing cert mainly)
- (void)documentPicker:(UIDocumentPickerViewController*)controller didPickDocumentsAtURLs:(nonnull NSArray<NSURL*>*)urls {
	if (urls.count != 2)
		return [Utils showError:self title:@"2 files must be selected! (p12 & mobileprovision)" error:nil];
	NSString* extension1 = urls.firstObject.pathExtension;
	NSString* extension2 = urls.lastObject.pathExtension;
	if ([extension1 isEqualToString:extension2])
		return [Utils showError:self title:@"You must only select 2 different files! Both the certificate (.p12) and the mobile provision profile! (.mobileprovision)" error:nil];
	AppLog(@"[Geode] Selected URLs: %@", urls);
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Input the password of the Certificate." message:@"This will be used for signing."
															preferredStyle:UIAlertControllerStyleAlert];
	[alert addTextFieldWithConfigurationHandler:^(UITextField* _Nonnull textField) {
		textField.placeholder = @"Certificate Password";
		textField.secureTextEntry = YES;
	}];
	UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* _Nonnull action) {
		NSError* err;
		NSURL* provisionURL;
		if (![extension1 isEqualToString:@"p12"]) {
			provisionURL = urls.firstObject;
		} else {
			provisionURL = urls.lastObject;
		}
		NSURL* newURL = [[LCPath docPath] URLByAppendingPathComponent:@"embedded.mobileprovision"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:newURL.path]) {
			[[NSFileManager defaultManager] removeItemAtURL:newURL error:&err];
			if (err)
				return [Utils showError:self title:@"Couldn't remove mobile provision from documents" error:err];
		}
		[[NSFileManager defaultManager] moveItemAtURL:provisionURL toURL:newURL error:&err];
		if (err)
			return [Utils showError:self title:@"Couldn't move mobile provision to documents" error:err]; // when would this error realistically happen
		UITextField* field = alert.textFields.firstObject;
		if ([extension1 isEqualToString:@"p12"]) {
			[self certPass:field.text url:urls.firstObject];
		} else {
			[self certPass:field.text url:urls.lastObject];
		}
	}];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	[alert addAction:okAction];
	[alert addAction:cancelAction];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)certPass:(NSString*)certPass url:(NSURL*)url {
	NSError* err;
	NSData* certData = [NSData dataWithContentsOfURL:url options:0 error:&err];
	if (err) {
		[Utils showError:self title:@"Couldn't read certificate" error:err];
		return;
	}
	NSString* teamId = [LCUtils getCertTeamIdWithKeyData:certData password:certPass];
	if (!teamId) {
		[Utils showError:self title:@"Couldn't get Team ID from certificate." error:nil];
		return;
	}
	AppLog(@"[Geode] Import complete!");
	NSUserDefaults* NSUD = [Utils getPrefs];
	[NSUD setObject:certPass forKey:@"LCCertificatePassword"];
	[NSUD setObject:certData forKey:@"LCCertificateData"];
	[NSUD setObject:teamId forKey:@"LCCertificateTeamId"];
	[NSUD setBool:YES forKey:@"LCCertificateImported"];
	[NSUD setBool:YES forKey:@"USE_ZSIGN"];
	[Utils showNotice:self title:@"Certificate Imported!"];
	[self.tableView reloadData];
}

@end
