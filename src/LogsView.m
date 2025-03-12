#import "LogsView.h"
#import "Utils.h"
#import "components/LogUtils.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LogsViewController ()
@property(nonatomic, strong) NSURL* fileURL;
@property(nonatomic, strong) UITextView* textView;
@end

@implementation LogsViewController

- (instancetype)initWithFile:(NSURL*)fileURL {
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		_fileURL = fileURL;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	UIBarButtonItem* shareButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.up"] style:UIBarButtonItemStylePlain target:self
																   action:@selector(shareLogs)];
	self.navigationItem.rightBarButtonItem = shareButton;

	self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
	self.textView.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
	self.textView.alwaysBounceVertical = YES;
	self.textView.contentSize = self.view.bounds.size;
	self.textView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
	self.textView.translatesAutoresizingMaskIntoConstraints = NO;
	self.textView.editable = NO;
	self.textView.selectable = YES;
	self.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

	self.view.clipsToBounds = YES;
	self.view.autoresizesSubviews = YES;

	// fix invisible padding
	self.textView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
	self.textView.textContainerInset = UIEdgeInsetsZero;

	[self.view addSubview:self.textView];
	[NSLayoutConstraint activateConstraints:@[
		[self.textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[self.textView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[self.textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[self.textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
	]];
	NSError* error;

	if ([self.fileURL checkResourceIsReachableAndReturnError:&error]) {
		self.textView.text = [NSString stringWithFormat:@"%@\n============================\n%@", self.fileURL.lastPathComponent,
														[NSString stringWithContentsOfURL:self.fileURL encoding:NSUTF8StringEncoding error:&error]];
	}
	if (error) {
		AppLog(@"Error reading log file: %@", error);
		self.textView.text = [@"logs.error" localizeWithFormat:self.fileURL.lastPathComponent];
	}
}

- (void)shareLogs {
	if (self.textView.text.length == 0) {
		[Utils showError:self title:@"logs.share-error".loc error:nil];
		return;
	}
	UIActivityViewController* activityViewController = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:self.fileURL, nil]
																						 applicationActivities:nil];
	activityViewController.popoverPresentationController.sourceView = self.view;
	[self presentViewController:activityViewController animated:YES completion:nil];
}

@end
