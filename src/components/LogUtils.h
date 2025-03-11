#import <Foundation/Foundation.h>

@interface LogUtils : NSObject

+ (void)log:(NSString*)format, ...;
+ (void)clearLogs;

@end
#define AppLog(x...) [LogUtils log:x];
