//
//  FileBrowserVC.m
//
//  Created on 2025-07-01
//

#import "FileBrowserVC.h"

@interface FileBrowserViewController ()

@property(nonatomic, strong) NSDateFormatter* dateFormatter;
@property(nonatomic, strong) NSByteCountFormatter* byteFormatter;

@end

@implementation FileBrowserViewController

#pragma mark - Initialization

- (instancetype)init {
	return [self initWithPath:NSHomeDirectory()];
}

- (instancetype)initWithPath:(NSString*)path {
	self = [super init];
	if (self) {
		_currentPath = [path copy];
		_fileItems = [[NSMutableArray alloc] init];
		[self setupFormatters];
	}
	return self;
}

- (void)setupFormatters {
	self.dateFormatter = [[NSDateFormatter alloc] init];
	self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
	self.dateFormatter.timeStyle = NSDateFormatterShortStyle;

	self.byteFormatter = [[NSByteCountFormatter alloc] init];
	self.byteFormatter.allowedUnits = NSByteCountFormatterUseAll;
	self.byteFormatter.countStyle = NSByteCountFormatterCountStyleFile;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupUI];
	[self refreshFileList];
}

- (void)setupUI {
	self.view.backgroundColor = [UIColor systemBackgroundColor];

	// Setup navigation
	self.title = [self.currentPath lastPathComponent];

	// Add navigation buttons
	if (![self.currentPath isEqualToString:NSHomeDirectory()]) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonTapped)];
	}

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped)];

	// Setup table view
	self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	[self.view addSubview:self.tableView];
}

#pragma mark - File Operations

- (void)refreshFileList {
	[self.fileItems removeAllObjects];

	NSError* error = nil;
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSArray* contents = [fileManager contentsOfDirectoryAtPath:self.currentPath error:&error];

	if (error) {
		[self showErrorAlert:error.localizedDescription];
		return;
	}

	// Sort contents: directories first, then files by latest modification date
	NSArray* sortedContents = [contents sortedArrayUsingComparator:^NSComparisonResult(NSString* file1, NSString* file2) {
		NSString* path1 = [self.currentPath stringByAppendingPathComponent:file1];
		NSString* path2 = [self.currentPath stringByAppendingPathComponent:file2];

		BOOL isDir1, isDir2;
		[fileManager fileExistsAtPath:path1 isDirectory:&isDir1];
		[fileManager fileExistsAtPath:path2 isDirectory:&isDir2];

		// Directories always come first
		if (isDir1 && !isDir2)
			return NSOrderedAscending;
		if (!isDir1 && isDir2)
			return NSOrderedDescending;

		// Within same type (both dirs or both files), sort by modification date (newest first)
		NSDictionary* attrs1 = [fileManager attributesOfItemAtPath:path1 error:nil];
		NSDictionary* attrs2 = [fileManager attributesOfItemAtPath:path2 error:nil];

		NSDate* date1 = attrs1[NSFileModificationDate];
		NSDate* date2 = attrs2[NSFileModificationDate];

		if (date1 && date2) {
			return [date2 compare:date1]; // Newest first
		}

		return [file1 caseInsensitiveCompare:file2];
	}];

	for (NSString* filename in sortedContents) {
		// Skip hidden files
		if ([filename hasPrefix:@"."])
			continue;

		NSString* fullPath = [self.currentPath stringByAppendingPathComponent:filename];
		NSDictionary* attributes = [fileManager attributesOfItemAtPath:fullPath error:nil];

		if (attributes) {
			NSMutableDictionary* fileInfo = [[NSMutableDictionary alloc] init];
			fileInfo[@"name"] = filename;
			fileInfo[@"path"] = fullPath;
			fileInfo[@"isDirectory"] = @([attributes[NSFileType] isEqualToString:NSFileTypeDirectory]);
			fileInfo[@"size"] = attributes[NSFileSize] ?: @0;
			fileInfo[@"modificationDate"] = attributes[NSFileModificationDate];

			[self.fileItems addObject:fileInfo];
		}
	}

	dispatch_async(dispatch_get_main_queue(), ^{ [self.tableView reloadData]; });
}

- (void)navigateToDirectory:(NSString*)directoryPath {
	FileBrowserViewController* newBrowser = [[FileBrowserViewController alloc] initWithPath:directoryPath];
	[self.navigationController pushViewController:newBrowser animated:YES];
}

- (void)deleteFileAtIndexPath:(NSIndexPath*)indexPath {
	if (indexPath.row >= self.fileItems.count)
		return;

	NSDictionary* fileInfo = self.fileItems[indexPath.row];
	NSString* filePath = fileInfo[@"path"];
	NSString* fileName = fileInfo[@"name"];

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Delete File" message:[NSString stringWithFormat:@"Are you sure you want to delete '%@'?", fileName]
															preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive
														 handler:^(UIAlertAction* action) { [self performDeleteForFilePath:filePath atIndexPath:indexPath]; }];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

	[alert addAction:deleteAction];
	[alert addAction:cancelAction];

	[self presentViewController:alert animated:YES completion:nil];
}

- (void)performDeleteForFilePath:(NSString*)filePath atIndexPath:(NSIndexPath*)indexPath {
	NSError* error = nil;
	BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];

	if (success) {
		[self.fileItems removeObjectAtIndex:indexPath.row];
		[self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
	} else {
		[self showErrorAlert:[NSString stringWithFormat:@"Failed to delete file: %@", error.localizedDescription]];
	}
}

#pragma mark - UI Actions

- (void)backButtonTapped {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)refreshButtonTapped {
	[self refreshFileList];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	return self.fileItems.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	static NSString* cellIdentifier = @"FileCell";

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	}

	NSDictionary* fileInfo = self.fileItems[indexPath.row];
	NSString* fileName = fileInfo[@"name"];
	BOOL isDirectory = [fileInfo[@"isDirectory"] boolValue];
	NSNumber* fileSize = fileInfo[@"size"];
	NSDate* modDate = fileInfo[@"modificationDate"];

	// Main text
	cell.textLabel.text = fileName;

	// Detail text with size and date
	NSString* sizeString = isDirectory ? @"Folder" : [self.byteFormatter stringFromByteCount:fileSize.longLongValue];
	NSString* dateString = [self.dateFormatter stringFromDate:modDate];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ • %@", sizeString, dateString];

	// Icon
	if (isDirectory) {
		cell.imageView.image = [UIImage systemImageNamed:@"folder.fill"];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	} else {
		cell.imageView.image = [UIImage systemImageNamed:@"doc.fill"];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}

	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	NSDictionary* fileInfo = self.fileItems[indexPath.row];
	BOOL isDirectory = [fileInfo[@"isDirectory"] boolValue];
	NSString* filePath = fileInfo[@"path"];

	if (isDirectory) {
		[self navigateToDirectory:filePath];
	} else {
		// For files, show file info
		[self showFileInfoForPath:filePath];
	}
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
	return YES;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self deleteFileAtIndexPath:indexPath];
	}
}

- (UISwipeActionsConfiguration*)tableView:(UITableView*)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath*)indexPath {
	UIContextualAction* deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete"
																			 handler:^(UIContextualAction* action, UIView* sourceView, void (^completionHandler)(BOOL)) {
																				 [self deleteFileAtIndexPath:indexPath];
																				 completionHandler(YES);
																			 }];

	deleteAction.image = [UIImage systemImageNamed:@"trash"];

	return [UISwipeActionsConfiguration configurationWithActions:@[ deleteAction ]];
}

#pragma mark - Helper Methods

- (void)showFileInfoForPath:(NSString*)filePath {
	NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
	if (!attributes)
		return;

	NSString* fileName = [filePath lastPathComponent];
	NSString* sizeString = [self.byteFormatter stringFromByteCount:[attributes[NSFileSize] longLongValue]];
	NSString* dateString = [self.dateFormatter stringFromDate:attributes[NSFileModificationDate]];

	NSString* message = [NSString stringWithFormat:@"Size: %@\nModified: %@\nPath: %@", sizeString, dateString, filePath];

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:fileName message:message preferredStyle:UIAlertControllerStyleAlert];

	// Add Preview option for text files
	if ([self isPreviewableFile:filePath]) {
		UIAlertAction* previewAction = [UIAlertAction actionWithTitle:@"Preview" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) { [self previewFile:filePath]; }];
		[alert addAction:previewAction];
	}

	[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

	[self presentViewController:alert animated:YES completion:nil];
}

- (void)showErrorAlert:(NSString*)message {
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];

	[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

	[self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)isPreviewableFile:(NSString*)filePath {
	NSString* extension = [[filePath pathExtension] lowercaseString];
	NSArray* previewableExtensions = @[ @"txt", @"text", @"log", @"md", @"json", @"xml", @"plist", @"css", @"js", @"html", @"htm", @"csv", @"rtf" ];
	return [previewableExtensions containsObject:extension];
}

- (void)previewFile:(NSString*)filePath {
	NSError* error = nil;

	// Check file size to avoid loading very large files
	NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
	NSNumber* fileSize = attributes[NSFileSize];

	if (fileSize && [fileSize longLongValue] > 1024 * 1024) { // 1MB limit
		[self showErrorAlert:@"File is too large to preview (>1MB)"];
		return;
	}

	NSString* content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];

	if (error || !content) {
		[self showErrorAlert:@"Unable to read file content"];
		return;
	}

	// Create preview view controller
	UIViewController* previewVC = [[UIViewController alloc] init];
	previewVC.title = [filePath lastPathComponent];
	previewVC.view.backgroundColor = [UIColor systemBackgroundColor];

	// Create text view for content
	UITextView* textView = [[UITextView alloc] init];
	textView.text = content;
	textView.font = [UIFont fontWithName:@"Menlo" size:14]; // Monospace font
	textView.editable = NO;
	textView.backgroundColor = [UIColor systemBackgroundColor];
	textView.textColor = [UIColor labelColor];
	textView.translatesAutoresizingMaskIntoConstraints = NO;

	[previewVC.view addSubview:textView];

	// Add constraints
	[NSLayoutConstraint activateConstraints:@[
		[textView.topAnchor constraintEqualToAnchor:previewVC.view.safeAreaLayoutGuide.topAnchor], [textView.leadingAnchor constraintEqualToAnchor:previewVC.view.leadingAnchor],
		[textView.trailingAnchor constraintEqualToAnchor:previewVC.view.trailingAnchor], [textView.bottomAnchor constraintEqualToAnchor:previewVC.view.bottomAnchor]
	]];

	// Add close button
	previewVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissPreview)];

	// Present in navigation controller
	UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:previewVC];
	[self presentViewController:navController animated:YES completion:nil];
}

- (void)dismissPreview {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
