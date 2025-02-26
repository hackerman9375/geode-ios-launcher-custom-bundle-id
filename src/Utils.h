#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utils : NSObject
+ (NSString*)gdBundleName;
+ (BOOL)isJailbroken;
+ (UIImageView *)imageViewFromPDF:(NSString *)pdfName;
+ (void)showError:(UIViewController*)root title:(NSString *)title error:(NSError*)error;
+ (NSString*)archName;
@end

