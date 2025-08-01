#import "EnterpriseCompare.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation EnterpriseCompare
+ (NSString*)getChecksum:(BOOL)helper {
	NSURL* from = [[NSBundle mainBundle] executableURL];
    NSURL* docPath = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
    NSURL* bundlePath = [[docPath URLByAppendingPathComponent:@"Applications"] URLByAppendingPathComponent:@"com.robtop.geometryjump.app"];
	if (!helper) {
		from = [bundlePath URLByAppendingPathComponent:@"GeometryOriginal"];
	}
	NSFileManager* fm = [NSFileManager defaultManager];
	NSError* error;
	if (![fm fileExistsAtPath:from.path]) return nil;
	NSMutableData* data = [NSMutableData dataWithContentsOfURL:from options:0 error:&error];
	if (!data || error) {
		NSLog(@"[Patcher] Couldn't read binary: %@", error);
		return nil;
	}
	NSMutableSet<NSString*>* modIDs = [NSMutableSet new];
	NSMutableSet<NSString*>* modDict = [NSMutableSet new];

	NSArray* modsDir = [fm contentsOfDirectoryAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"mods"] error:nil];
	if (!helper) {
		modsDir = [fm contentsOfDirectoryAtPath:[bundlePath.path stringByAppendingPathComponent:@"mods"] error:nil];
	}
	for (NSString *file in modsDir) {
		NSString *modID = [[file stringByDeletingPathExtension] stringByDeletingPathExtension];
		if (![modDict containsObject:file]) {
			[modIDs addObject:modID];
			[modDict addObject:file];
		}
	}
	NSMutableArray* modIDSorted = [[[modIDs allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
	for (int i = 0; i < modIDSorted.count; i++) {
		NSString *item = modIDSorted[i];
		if (item == nil || [item isEqualToString:@""]) {
			[modIDSorted removeObjectAtIndex:i];
		}
	}

	NSData* stringData = [[NSString stringWithFormat:@"%@",[modIDSorted componentsJoinedByString:@","]] dataUsingEncoding:NSUTF8StringEncoding];
	unsigned char digest[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256(stringData.bytes, (CC_LONG)stringData.length, digest);
	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
	for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", digest[i]];
	}

	return output;
}
@end
