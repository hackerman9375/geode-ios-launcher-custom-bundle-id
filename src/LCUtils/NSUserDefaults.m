//
//  NSUserDefaults.m
//  LiveContainer
//
//  Created by s s on 2024/11/29.
//

#import "FoundationPrivate.h"
#import "GCSharedUtils.h"
#import "utils.h"

@interface NSUserDefaults (Geode)
+ (instancetype)gcSharedDefaults;
+ (instancetype)gcUserDefaults;
+ (NSString*)gcAppUrlScheme;
+ (NSString*)gcAppGroupPath;
@end

NSMutableDictionary* LCPreferences = 0;

void NUDGuestHooksInit() {
	LCPreferences = [[NSMutableDictionary alloc] init];
	NSFileManager* fm = NSFileManager.defaultManager;
	NSURL* libraryPath = [fm URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].lastObject;
	NSURL* preferenceFolderPath = [libraryPath URLByAppendingPathComponent:@"Preferences"];
	if (![fm fileExistsAtPath:preferenceFolderPath.path]) {
		NSError* error;
		[fm createDirectoryAtPath:preferenceFolderPath.path withIntermediateDirectories:YES attributes:@{} error:&error];
	}
}
