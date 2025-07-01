//
//  FileBrowserViewController.h
//
//  Created on 2025-07-01
//

#import <UIKit/UIKit.h>

@interface FileBrowserViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UITableView* tableView;
@property(nonatomic, strong) NSString* currentPath;
@property(nonatomic, strong) NSMutableArray<NSDictionary*>* fileItems;
@property(nonatomic, strong) UINavigationItem* navItem;

// Initialization
- (instancetype)initWithPath:(NSString*)path;

// File operations
- (void)refreshFileList;
- (void)navigateToDirectory:(NSString*)directoryPath;
- (void)deleteFileAtIndexPath:(NSIndexPath*)indexPath;

// Preview operations
- (BOOL)isPreviewableFile:(NSString*)filePath;
- (void)previewFile:(NSString*)filePath;
- (void)dismissPreview;

// UI Actions
- (void)backButtonTapped;
- (void)refreshButtonTapped;

@end
