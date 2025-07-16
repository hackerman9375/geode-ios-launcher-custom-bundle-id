//
//  NSUDBrowserVC.m
//
//  Created on 2025-07-15
//

//
//  UserDefaultsEditorViewController.m
//
//  A table view controller for viewing and editing NSUserDefaults values
//

#import "NSUDBrowserVC.h"
#import "src/Utils.h"

@interface NSUDBrowserVC () <UIAlertViewDelegate>

@property(nonatomic, strong) NSMutableArray<NSString*>* keys;
@property(nonatomic, strong) NSMutableDictionary* userDefaultsDict;
@property(nonatomic, strong) UIBarButtonItem* editButton;
@property(nonatomic, strong) UIBarButtonItem* addButton;

@end

@implementation NSUDBrowserVC

#pragma mark - Initialization

- (instancetype)init {
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		_editingEnabled = NO;
		[self loadUserDefaults];
	}
	return self;
}
#pragma mark - View Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Preferences";
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	[self setupNavigationBar];
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UserDefaultCell"];
}

- (void)setupNavigationBar {
	if (self.editingEnabled) {
		self.editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editButtonTapped:)];

		self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTapped:)];

		self.navigationItem.rightBarButtonItems = @[ self.editButton, self.addButton ];
	}

	UIBarButtonItem* refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped:)];
	self.navigationItem.leftBarButtonItem = refreshButton;
}

#pragma mark - Data Management

- (void)loadUserDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary* allDefaults = [defaults dictionaryRepresentation];
	self.userDefaultsDict = [NSMutableDictionary dictionaryWithDictionary:allDefaults];
	self.keys = [NSMutableArray arrayWithArray:[allDefaults allKeys]];
	[self.keys sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (void)refreshUserDefaults {
	[self loadUserDefaults];
	[self.tableView reloadData];
}

#pragma mark - Actions

- (void)editButtonTapped:(UIBarButtonItem*)sender {
	if (self.tableView.editing) {
		[self.tableView setEditing:NO animated:YES];
		self.editButton.title = @"Edit";
		self.addButton.enabled = YES;
	} else {
		[self.tableView setEditing:YES animated:YES];
		self.editButton.title = @"Done";
		self.addButton.enabled = NO;
	}
}

- (void)addButtonTapped:(UIBarButtonItem*)sender {
	[self showAddNewKeyAlert];
}

- (void)refreshButtonTapped:(UIBarButtonItem*)sender {
	[self refreshUserDefaults];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	return self.keys.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"UserDefaultCell" forIndexPath:indexPath];
	if (cell.detailTextLabel == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UserDefaultCell"];
	}
	NSString* key = self.keys[indexPath.row];
	id value = self.userDefaultsDict[key];
	cell.textLabel.text = key;
	if ([self isValueReadable:value]) {
		cell.detailTextLabel.text = [self previewStringForValue:value];
		cell.detailTextLabel.textColor = [UIColor systemBlueColor];
		cell.detailTextLabel.numberOfLines = 1;
		cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	} else {
		cell.detailTextLabel.text = [self stringForValue:value];
		cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
		cell.detailTextLabel.numberOfLines = 1;
		cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	}
	cell.accessoryType = self.editingEnabled ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	return cell;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
	return self.editingEnabled;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSString* key = self.keys[indexPath.row];
		[self deleteUserDefaultForKey:key atIndexPath:indexPath];
	}
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	if (self.editingEnabled) {
		NSString* key = self.keys[indexPath.row];
		id value = self.userDefaultsDict[key];
		[self showEditAlertForKey:key currentValue:value];
	}
}

#pragma mark - Alert Methods

- (void)showAddNewKeyAlert {
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Add New Key" message:@"Enter key name and value" preferredStyle:UIAlertControllerStyleAlert];

	[alert addTextFieldWithConfigurationHandler:^(UITextField* textField) { textField.placeholder = @"Key"; }];

	[alert addTextFieldWithConfigurationHandler:^(UITextField* textField) { textField.placeholder = @"Value"; }];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

	UIAlertAction* addAction = [UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		UITextField* keyField = alert.textFields[0];
		UITextField* valueField = alert.textFields[1];

		if (keyField.text.length > 0 && valueField.text.length > 0) {
			[self addUserDefaultForKey:keyField.text value:valueField.text];
		}
	}];

	[alert addAction:cancelAction];
	[alert addAction:addAction];

	[self presentViewController:alert animated:YES completion:nil];
}

- (void)showEditAlertForKey:(NSString*)key currentValue:(id)currentValue {
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Edit Value" message:[NSString stringWithFormat:@"Key: %@", key]
															preferredStyle:UIAlertControllerStyleAlert];

	[alert addTextFieldWithConfigurationHandler:^(UITextField* textField) {
		textField.text = [self stringForValue:currentValue];
		textField.placeholder = @"Value";
	}];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

	UIAlertAction* saveAction = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		UITextField* valueField = alert.textFields[0];
		[self updateUserDefaultForKey:key newValue:valueField.text];
	}];

	UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[self.keys indexOfObject:key] inSection:0];
		[self deleteUserDefaultForKey:key atIndexPath:indexPath];
	}];

	[alert addAction:cancelAction];
	[alert addAction:saveAction];
	[alert addAction:deleteAction];

	[self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - User Defaults Operations

- (void)addUserDefaultForKey:(NSString*)key value:(NSString*)value {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	// Try to infer the type and convert the value
	id convertedValue = [self convertStringToAppropriateType:value];

	[defaults setObject:convertedValue forKey:key];
	[defaults synchronize];

	// Update local data
	self.userDefaultsDict[key] = convertedValue;
	[self.keys addObject:key];
	[self.keys sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

	[self.tableView reloadData];
}

- (void)updateUserDefaultForKey:(NSString*)key newValue:(NSString*)newValue {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	// Try to infer the type and convert the value
	id convertedValue = [self convertStringToAppropriateType:newValue];

	[defaults setObject:convertedValue forKey:key];
	[defaults synchronize];

	// Update local data
	self.userDefaultsDict[key] = convertedValue;

	// Refresh the specific row
	NSInteger row = [self.keys indexOfObject:key];
	if (row != NSNotFound) {
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:0];
		[self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void)deleteUserDefaultForKey:(NSString*)key atIndexPath:(NSIndexPath*)indexPath {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:key];
	[defaults synchronize];

	// Update local data
	[self.userDefaultsDict removeObjectForKey:key];
	[self.keys removeObject:key];

	[self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Helper Methods

- (BOOL)isValueReadable:(id)value {
	return [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSDate class]];
}

- (NSString*)previewStringForValue:(id)value {
	if ([value isKindOfClass:[NSString class]]) {
		NSString* stringValue = (NSString*)value;
		// Limit preview to 50 characters
		if (stringValue.length > 50) {
			return [NSString stringWithFormat:@"%@...", [stringValue substringToIndex:47]];
		}
		return stringValue;
	} else if ([value isKindOfClass:[NSNumber class]]) {
		NSNumber* number = (NSNumber*)value;

		// Check if it's a boolean value
		if (strcmp([number objCType], @encode(BOOL)) == 0) {
			return [number boolValue] ? @"YES" : @"NO";
		}

		// Check if it's an integer
		if (strcmp([number objCType], @encode(int)) == 0 || strcmp([number objCType], @encode(long)) == 0 || strcmp([number objCType], @encode(long long)) == 0) {
			return [NSString stringWithFormat:@"%lld", [number longLongValue]];
		}

		// Check if it's a float/double
		if (strcmp([number objCType], @encode(float)) == 0 || strcmp([number objCType], @encode(double)) == 0) {
			return [NSString stringWithFormat:@"%.2f", [number doubleValue]];
		}

		return [number stringValue];
	} else if ([value isKindOfClass:[NSDate class]]) {
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		formatter.dateStyle = NSDateFormatterMediumStyle;
		formatter.timeStyle = NSDateFormatterShortStyle;
		return [formatter stringFromDate:(NSDate*)value];
	}

	return [self stringForValue:value];
}

- (NSString*)stringForValue:(id)value {
	if ([value isKindOfClass:[NSString class]]) {
		return (NSString*)value;
	} else if ([value isKindOfClass:[NSNumber class]]) {
		NSNumber* number = (NSNumber*)value;
		return [number stringValue];
	} else if ([value isKindOfClass:[NSDate class]]) {
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		formatter.dateStyle = NSDateFormatterShortStyle;
		formatter.timeStyle = NSDateFormatterShortStyle;
		return [formatter stringFromDate:(NSDate*)value];
	} else if ([value isKindOfClass:[NSArray class]]) {
		return [NSString stringWithFormat:@"Array (%lu items)", (unsigned long)[(NSArray*)value count]];
	} else if ([value isKindOfClass:[NSDictionary class]]) {
		return [NSString stringWithFormat:@"Dictionary (%lu items)", (unsigned long)[(NSDictionary*)value count]];
	} else if ([value isKindOfClass:[NSData class]]) {
		return [NSString stringWithFormat:@"Data (%lu bytes)", (unsigned long)[(NSData*)value length]];
	} else {
		return [value description];
	}
}

- (id)convertStringToAppropriateType:(NSString*)string {
	// Try to convert to number first
	NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
	NSNumber* number = [formatter numberFromString:string];
	if (number) {
		return number;
	}

	// Check for boolean values
	if ([string.lowercaseString isEqualToString:@"true"] || [string.lowercaseString isEqualToString:@"yes"]) {
		return @YES;
	} else if ([string.lowercaseString isEqualToString:@"false"] || [string.lowercaseString isEqualToString:@"no"]) {
		return @NO;
	}

	// Default to string
	return string;
}

@end
