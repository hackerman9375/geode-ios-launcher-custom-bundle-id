#import "AppDelegate.h"
#import "IntroVC.h"
#import "LCUtils/LCUtils.h"
#import "Utils.h"
#import "Theming.h"
#import "RootViewController.h"

// https://www.uicolor.io/
@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [Theming getBackgroundColor];
//18, 19, 24

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"CompletedSetup"]) {
        RootViewController *rootViewController = [[RootViewController alloc] init];
        self.window.rootViewController = rootViewController;
    } else {
        IntroVC* introViewController = [[IntroVC alloc] init];
        self.window.rootViewController = introViewController;
    }

    [self.window makeKeyAndVisible];
    return YES;
}

// ext

+ (void)openWebPage:(NSString *)urlStr {
    AppDelegate *delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    if (!delegate.openUrlStrFunc) {
        delegate.urlStrToOpen = urlStr;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            delegate.openUrlStrFunc(urlStr);
        });
    }
}

+ (void)setOpenUrlStrFunc:(void (^)(NSString *urlStr))handler {
    AppDelegate *delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    delegate.openUrlStrFunc = handler;
    if (delegate.urlStrToOpen) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(delegate.urlStrToOpen);
            delegate.urlStrToOpen = nil;
        });
    }
    NSString *storedUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"webPageToOpen"];
    if (storedUrl) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"webPageToOpen"];
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(storedUrl);
        });
    }
}

+ (void)setLaunchAppFunc:(void (^)(NSString *bundleId, NSString *container))handler {
    AppDelegate *delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    delegate.launchAppFunc = handler;
    if (delegate.bundleToLaunch) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(delegate.bundleToLaunch, delegate.containerToLaunch);
            delegate.bundleToLaunch = nil;
            delegate.containerToLaunch = nil;
        });
    }
}

+ (void)launchApp:(NSString *)bundleId container:(NSString *)container {
    AppDelegate *delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    if (!delegate.launchAppFunc) {
        delegate.bundleToLaunch = bundleId;
        delegate.containerToLaunch = container;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            delegate.launchAppFunc(bundleId, container);
        });
    }
}

- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([url.host isEqualToString:@"open-web-page"]) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        for (NSURLQueryItem *item in components.queryItems) {
            if ([item.name isEqualToString:@"q"]) {
                NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:item.value options:0];
                if (decodedData) {
                    NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
                    if (decodedString) {
                        [AppDelegate openWebPage:decodedString];
                    }
                }
            }
        }
    } else if ([url.host isEqualToString:@"geode-launch"] || [url.host isEqualToString:@"launch"] || [url.host isEqualToString:@"relaunch"]) {
        [[NSUserDefaults standardUserDefaults] setValue:[Utils gdBundleName] forKey:@"selected"];
        [[NSUserDefaults standardUserDefaults] setValue:@"GeometryDash" forKey:@"selectedContainer"];
        if ([url.host isEqualToString:@"relaunch"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"USE_TWEAK"]) return NO;
        [LCUtils launchToGuestApp];
    } else if ([url.host isEqualToString:@"safe-mode"]) {
        [[NSUserDefaults standardUserDefaults] setValue:[Utils gdBundleName] forKey:@"selected"];
        [[NSUserDefaults standardUserDefaults] setValue:@"GeometryDash" forKey:@"selectedContainer"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"safemode"];
        [LCUtils launchToGuestApp];
    }
    return NO;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"selected"];
    [defaults removeObjectForKey:@"selectedContainer"];
    if ([defaults objectForKey:@"LCLastLanguages"]) {
        [defaults setObject:[defaults objectForKey:@"LCLastLanguages"] forKey:@"AppleLanguages"];
        [defaults removeObjectForKey:@"LCLastLanguages"];
    }
}

@end
