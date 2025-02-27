#import "LogsView.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface LogsViewController ()
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) UITextView *textView;
@end

@implementation LogsViewController

- (instancetype)initWithFile:(NSURL *)fileURL {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _fileURL = fileURL;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.editable = NO;
    self.textView.selectable = YES;

    self.textView.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.textView.alwaysBounceVertical = YES;
    [self.view addSubview:self.textView];
    NSError *error;

    if ([self.fileURL checkResourceIsReachableAndReturnError:&error]) {
        self.textView.text = [NSString stringWithFormat:@"%@\n============================\n%@", self.fileURL.lastPathComponent, [NSString stringWithContentsOfURL:self.fileURL encoding:NSUTF8StringEncoding error:&error]];
    }
    if (error) {
        NSLog(@"Error reading log file: %@", error);
        self.textView.text = [NSString stringWithFormat:@"%@ could not be read.", self.fileURL.lastPathComponent];
    }
}

@end
