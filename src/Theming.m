#import "Theming.h"

@implementation Theming
+ (UIColor*)getDarkColor {
    return [UIColor colorWithRed: 0.15 green: 0.15 blue: 0.15 alpha: 1.00];
}
+ (UIColor*)getBackgroundColor {
    return [UIColor colorWithRed: 0.07 green: 0.07 blue: 0.09 alpha: 1.00];
}
+ (UIColor *)getAccentColor {
    NSData *colorData = [[NSUserDefaults standardUserDefaults] dataForKey:@"accentColor"];
    NSError *error = nil;
    if (colorData) {
        UIColor *accentColor = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:colorData error:&error];
        if (accentColor) {
            return accentColor;
        } else if (error) {
            NSLog(@"Couldn't unarchive accent color: %@", error);
        }
    }
    return [UIColor colorWithRed: 0.70 green: 0.77 blue: 1.00 alpha: 1.00];
    // apple loves blue
    //return [UIColor systemBlueColor];
}

+ (void)saveAccentColor:(UIColor *)color {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSError *error = nil;
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color requiringSecureCoding:YES error:&error];
    if (error) {
        NSLog(@"Couldn't archive accent color: %@", error);
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
