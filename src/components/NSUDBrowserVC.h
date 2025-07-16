//
//  NSUDBrowserVC.h
//
//  Created on 2025-07-15
//

#import <UIKit/UIKit.h>

@interface NSUDBrowserVC : UITableViewController
- (void)refreshUserDefaults;
@property(nonatomic, assign) BOOL editingEnabled;
@end
