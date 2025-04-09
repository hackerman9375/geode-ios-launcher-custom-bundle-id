#import "LogUtils.h"
#include "src/Utils.h"

static const NSUInteger MAX_LOG_FILE_SIZE = 1024 * 1024; // 1 MB
static dispatch_queue_t loggingQueue;

@implementation LogUtils

+ (void)initialize {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ loggingQueue = dispatch_queue_create("com.geode.logqueue", DISPATCH_QUEUE_SERIAL); });
}

+ (NSString*)logFilePath {
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths[0] hasSuffix:@"GeometryDash/Documents"]) {
		// a fix since im lazy to actually get the shared doc
		return [paths[0] stringByAppendingPathComponent:@"../../../../app.log"];
	} else {
		return [paths[0] stringByAppendingPathComponent:@"app.log"];
	}
}

+ (void)log:(NSString*)format, ... {
	NSString* callSource = [[NSThread callStackSymbols] objectAtIndex:1];
	if (!callSource)
		callSource = @"[Unknown]";

	NSArray* parts = [callSource componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
	NSString* srcFunc = @"Unknown";

	if (parts.count > 1)
		srcFunc = [parts objectAtIndex:1];

	NSString* prefix = [NSString stringWithFormat:@"[GeodeLauncher/%@] ", [srcFunc substringToIndex:MIN([srcFunc rangeOfString:@" "].location, srcFunc.length)]];
	format = [prefix stringByAppendingString:format];

	va_list args;
	va_start(args, format);
	NSString* message = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	NSLog(@"%@", message);
	dispatch_async(loggingQueue, ^{
		[self checkLogFileSize];
		NSFileHandle* fileHandle = [NSFileHandle fileHandleForWritingAtPath:[self logFilePath]];
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
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSString* logPath = [self logFilePath];

	if ([fileManager fileExistsAtPath:logPath]) {
		NSError* error = nil;
		NSDictionary* attrs = [fileManager attributesOfItemAtPath:logPath error:&error];
		if (!error && [attrs fileSize] > MAX_LOG_FILE_SIZE) {
			[@"" writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
		}
	}
}

+ (void)clearLogs {
	if ([[Utils getPrefs] integerForKey:@"LAUNCH_COUNT"] % 5 == 0) {
		dispatch_sync(loggingQueue, ^{
			NSError* error = nil;
			[@"" writeToFile:[self logFilePath] atomically:YES encoding:NSUTF8StringEncoding error:&error];
		});
	}
}

@end
