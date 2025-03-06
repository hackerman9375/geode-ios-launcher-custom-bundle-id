#import "Theming.h"
#import "Utils.h"

@implementation Theming
+ (BOOL)darkModeEnabled {
    UIWindow *keyWindow = nil;
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) {
            keyWindow = window;
            break;
        }
    }
    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].windows.firstObject;
    }
    if (!keyWindow) {
        return NO;
    }
    return (keyWindow.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
}
+ (UIColor*)getDarkColor {
    if ([Theming darkModeEnabled]) {
        return [UIColor colorWithRed: 0.15 green: 0.15 blue: 0.15 alpha: 1.00];
    } else {
        return [UIColor colorWithRed: 0.85 green: 0.85 blue: 0.85 alpha: 1.00];
    }
}
+ (UIColor*)getBackgroundColor {
    if ([Theming darkModeEnabled]) {
        return [UIColor colorWithRed: 0.07 green: 0.07 blue: 0.09 alpha: 1.00];
    } else {
        return [UIColor colorWithRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.00];
    }
}
+ (UIColor *)getWhiteColor {
    if ([Theming darkModeEnabled]) {
        return [UIColor whiteColor];
    } else {
        return [UIColor blackColor];
    }
}
+ (UIColor *)getFooterColor {
    if ([Theming darkModeEnabled]) {
        return [UIColor lightGrayColor];
    } else {
        return [UIColor darkGrayColor];
    }
}
+ (UIColor *)getAccentColor {
    NSData *colorData = [[Utils getPrefs] dataForKey:@"accentColor"];
    NSError *error = nil;
    if (colorData) {
        UIColor *accentColor = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:colorData error:&error];
        if (accentColor) {
            return accentColor;
        } else if (error) {
            NSLog(@"[Geode] Couldn't unarchive accent color: %@", error);
        }
    }
    if ([Theming darkModeEnabled]) {
        return [UIColor colorWithRed: 0.70 green: 0.77 blue: 1.00 alpha: 1.00];
    } else {
        return [UIColor colorWithRed: 0.4 green: 0.55 blue: 1.00 alpha: 1.00];
    }
    // apple loves blue
    //return [UIColor systemBlueColor];
}

+ (void)saveAccentColor:(UIColor *)color {
    NSUserDefaults *userDefaults = [Utils getPrefs];
    NSError *error = nil;
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color requiringSecureCoding:YES error:&error];
    if (error) {
        NSLog(@"[Geode] Couldn't archive accent color: %@", error);
        return;
    }
    [userDefaults setObject:colorData forKey:@"accentColor"];
}

+ (UIColor*)getTextColor:(UIColor *)color {
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    CGFloat brightness = (0.299 * red) + (0.587 * green) + (0.114 * blue);
    return brightness > 0.5 ? [UIColor blackColor] : [UIColor whiteColor];
}
@end
