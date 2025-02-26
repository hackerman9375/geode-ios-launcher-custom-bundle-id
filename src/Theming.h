#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Theming : NSObject
+ (UIColor*)getDarkColor;
+ (UIColor*)getBackgroundColor;
+ (UIColor*)getAccentColor;
+ (UIColor*)getTextColor:(UIColor*)color;
+ (void)saveAccentColor:(UIColor *)color;
@end
