#import "AppDelegate.h"
#import "RootViewController.h"

// https://www.uicolor.io/
@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor colorWithRed: 0.07 green: 0.07 blue: 0.09 alpha: 1.00];
//18, 19, 24
    RootViewController *rootViewController = [[RootViewController alloc] init];
    self.window.rootViewController = rootViewController;

    [self.window makeKeyAndVisible];
    return YES;
}

@end
