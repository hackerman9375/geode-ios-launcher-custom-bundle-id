#import "LogUtils.h"
#include "src/Utils.h"

static const NSUInteger MAX_LOG_FILE_SIZE = 1024 * 1024; // 1 MB
static dispatch_queue_t loggingQueue;

@implementation LogUtils

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loggingQueue = dispatch_queue_create("com.geode.logqueue", DISPATCH_QUEUE_SERIAL);
    });
}

+ (NSString *)logFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:@"app.log"];
}

+ (void)log:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSLog(@"%@", message);
    dispatch_async(loggingQueue, ^{
        [self checkLogFileSize];
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:[self logFilePath]];
        if (fileHandle) {
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[[message stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        } else {
            [[message stringByAppendingString:@"\n"] writeToFile:[self logFilePath] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    });
}

+ (void)checkLogFileSize {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *logPath = [self logFilePath];
    
    if ([fileManager fileExistsAtPath:logPath]) {
        NSError *error = nil;
        NSDictionary *attrs = [fileManager attributesOfItemAtPath:logPath error:&error];
        if (!error && [attrs fileSize] > MAX_LOG_FILE_SIZE) {
            [@"" writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
}

+ (void)clearLogs {
    if ([[Utils getPrefs] integerForKey:@"LAUNCH_COUNT"] % 5 == 0) {
        dispatch_sync(loggingQueue, ^{ // Ensure clear completes before returning
            NSError *error = nil;
            [@"" writeToFile:[self logFilePath] atomically:YES encoding:NSUTF8StringEncoding error:&error];
        });
    }
}

@end
