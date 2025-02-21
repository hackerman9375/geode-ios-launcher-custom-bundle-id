#import <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

@interface Utils : NSObject
+ (BOOL)isJailbroken;
+ (UIImageView *)imageViewFromPDF:(NSString *)pdfName;
@end
