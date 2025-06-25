#import "JITLessVC.h"
#import "LCUtils/LCUtils.h"
#import "Theming.h"
#import "Utils.h"
#import "components/LogUtils.h"

@implementation JITLessVC
- (void)viewDidLoad {
	[super viewDidLoad];
	[self setTitle:@"JIT-Less"];
	// https://github.com/reactwg/react-native-new-architecture/blob/76d8426c27c1bf30c235f653e425ef872554a33b/docs/fabric-native-components.md
	[NSLayoutConstraint activateConstraints:@[
		[self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
	]];
	[[self view] setBackgroundColor:[Theming getBackgroundColor]];
}
- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
}
#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	return 8;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	UITableViewCell* cellval1 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
	cellval1.selectionStyle = UITableViewCellSelectionStyleNone;
	switch (indexPath.row) {
	case 0: {
		cellval1.textLabel.text = @"Bundle ID";
		cellval1.detailTextLabel.text = [[NSBundle mainBundle] bundleIdentifier];
		return cellval1;
	}
	case 1: {
		cellval1.textLabel.text = @"App Group ID";
		if ([LCUtils appGroupID] != nil) {
			cellval1.detailTextLabel.text = [LCUtils appGroupID];
			cellval1.detailTextLabel.textColor = [UIColor systemGreenColor];
		} else {
			cellval1.detailTextLabel.text = @"Unknown";
			cellval1.detailTextLabel.textColor = [UIColor systemRedColor];
		}
		return cellval1;
	}
	case 2: {
		cellval1.textLabel.text = @"Store";
		cellval1.detailTextLabel.text = [LCUtils getStoreName];
		return cellval1;
	}
	case 3: {
		NSString* patchChecksum = [[Utils getPrefs] stringForKey:@"PATCH_CHECKSUM"];
		cellval1.textLabel.text = @"Patched";
		if (patchChecksum && [patchChecksum isEqualToString:@"NO"]) {
			cellval1.detailTextLabel.text = @"common.no".loc;
			cellval1.detailTextLabel.textColor = [UIColor systemRedColor];
		} else {
			cellval1.detailTextLabel.text = @"common.yes".loc;
			cellval1.detailTextLabel.textColor = [UIColor systemGreenColor];
		}
		return cellval1;
	}
	case 4: {
		cellval1.textLabel.text = @"Certificate Data";
		if ([LCUtils certificateData] != nil) {
			cellval1.detailTextLabel.text = @"common.found".loc;
			cellval1.detailTextLabel.textColor = [UIColor systemGreenColor];
		} else {
			cellval1.detailTextLabel.text = @"common.notfound".loc;
			cellval1.detailTextLabel.textColor = [UIColor systemRedColor];
		}
		return cellval1;
	}
	case 5: {
		cellval1.textLabel.text = @"Certificate Password";
		if ([LCUtils certificatePassword] != nil) {
			cellval1.detailTextLabel.text = @"common.found".loc;
			cellval1.detailTextLabel.textColor = [UIColor systemGreenColor];
		} else {
			cellval1.detailTextLabel.text = @"common.notfound".loc;
			cellval1.detailTextLabel.textColor = [UIColor systemRedColor];
		}
		return cellval1;
	}
	case 6: {
		NSDate* date = [[Utils getPrefs] objectForKey:@"LCCertificateUpdateDate"];
		if (date == nil) {
			cellval1.detailTextLabel.text = @"Unknown";
		} else {
			NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
			formatter.dateStyle = NSDateFormatterShortStyle;
			formatter.timeStyle = NSDateFormatterMediumStyle;
			cellval1.detailTextLabel.text = [formatter stringFromDate:date];
		}
		cellval1.textLabel.text = @"Cert Last Update";
		return cellval1;
	}
	case 7: {
		cellval1.textLabel.text = @"get-task-allow";
		if ([Utils isDevCert]) {
			cellval1.detailTextLabel.text = @"common.yes".loc;
			cellval1.detailTextLabel.textColor = [UIColor systemGreenColor];
		} else {
			cellval1.detailTextLabel.text = @"common.no".loc;
			cellval1.detailTextLabel.textColor = [UIColor systemRedColor];
		}
		return cellval1;
	}
	}
	return cell;
}

// Test JIT-Less
- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
