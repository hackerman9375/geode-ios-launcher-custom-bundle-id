#import "Localization.h"

@implementation NSString (Localization)
- (NSString *)localized {
    NSString *str = NSLocalizedString(self, nil);
    if ([str isEqualToString:self]) { // no translations found!
        NSDictionary *enLocal = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"en.lproj/Localizable.strings"]];
        str = enLocal[self];
        if (!str) {
            str = self;
        }
    }
    return str;
}
- (NSString *)localizeWithFormat:(NSString *)arg1, ... {
    va_list args;
    va_start(args, arg1);
    NSString *formattedString = [NSString localizedStringWithFormat:[self localized], arg1, args];
    va_end(args);
    return formattedString;
}
@end
