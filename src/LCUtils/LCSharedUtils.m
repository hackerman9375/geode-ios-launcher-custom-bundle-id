#import "LCSharedUtils.h"
#import "UIKitPrivate.h"
#import "src/LCUtils/LCAppInfo.h"
#import "src/LCUtils/LCUtils.h"
#import "src/LCUtils/Shared.h"
#import "src/Utils.h"
#import "src/components/LogUtils.h"

extern NSUserDefaults* lcUserDefaults;
extern NSString* lcAppUrlScheme;
extern NSBundle* lcMainBundle;

@implementation LCSharedUtils

+ (NSString*)teamIdentifier {
	static NSString* ans = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ ans = [[lcMainBundle.bundleIdentifier componentsSeparatedByString:@"."] lastObject]; });
	return ans;
}

+ (NSString*)appGroupID {
	static dispatch_once_t once;
	static NSString* appGroupID = @"Unknown";
	dispatch_once(&once, ^{
		NSArray* possibleAppGroups = @[
			[@"group.com.SideStore.SideStore." stringByAppendingString:[self teamIdentifier]], [@"group.com.rileytestut.AltStore." stringByAppendingString:[self teamIdentifier]]
		];

		for (NSString* group in possibleAppGroups) {
			NSURL* path = [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:group];
			NSURL* bundlePath = [path URLByAppendingPathComponent:@"Apps/com.geode.launcher/App.app"];
			if ([NSFileManager.defaultManager fileExistsAtPath:bundlePath.path]) {
				// This will fail if LiveContainer is installed in both stores, but it should never be the case
				appGroupID = group;
				return;
			}
		}
	});
	return appGroupID;
}

+ (NSURL*)appGroupPath {
	static NSURL* appGroupPath = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ appGroupPath = [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:[LCSharedUtils appGroupID]]; });
	return appGroupPath;
}

+ (NSString*)certificatePassword {
	if ([lcUserDefaults boolForKey:@"LCCertificateImported"]) {
		NSString* ans = [lcUserDefaults objectForKey:@"LCCertificatePassword"];
		return ans;
	} else {
		// password of cert retrieved from the store tweak is always @"". We just keep this function so we can check if certificate presents without changing codes.
		NSString* ans = [[[NSUserDefaults alloc] initWithSuiteName:[self appGroupID]] objectForKey:@"LCCertificatePassword"];
		if (ans) {
			return @"";
		} else {
			return nil;
		}
	}
}

+ (void)relaunchApp {
	[lcUserDefaults setValue:[Utils gdBundleName] forKey:@"selected"];
	[lcUserDefaults setValue:@"GeometryDash" forKey:@"selectedContainer"];
	if ([lcUserDefaults boolForKey:@"USE_TWEAK"] && [Utils isJailbroken]) {
		NSString* appBundleIdentifier = @"com.robtop.geometryjump";
		[[LSApplicationWorkspace defaultWorkspace] openApplicationWithBundleID:appBundleIdentifier];
		exit(0);
		return;
	}
	if ([lcUserDefaults boolForKey:@"JITLESS"]) {
		LCAppInfo* app = [[LCAppInfo alloc] initWithBundlePath:[[LCPath bundlePath] URLByAppendingPathComponent:@"com.robtop.geometryjump.app"].path];
		app.signer = [lcUserDefaults boolForKey:@"USE_ZSIGN"] ? 1 : 0;
		if ([[Utils getPrefs] boolForKey:@"LCCertificateImported"]) {
			app.signer = ZSign;
		}
		[LCUtils signMods:[[LCPath docPath] URLByAppendingPathComponent:@"game/geode"] force:NO signer:app.signer progressHandler:^(NSProgress* progress) {}
			completion:^(NSError* error) {
				if (error != nil) {
					AppLog(@"Detailed error for signing mods: %@", error);
				}
				[LCUtils launchToGuestApp];
			}];
	} else {
		if (![LCSharedUtils askForJIT])
			return;
		[LCSharedUtils launchToGuestApp];
	}
}

+ (BOOL)launchToGuestApp {
	UIApplication* application = [NSClassFromString(@"UIApplication") sharedApplication];
	NSString* urlScheme;

	NSString* tsPath = [NSString stringWithFormat:@"%@/../_TrollStore", lcMainBundle.bundlePath];
	int tries = 1;
	if (!access(tsPath.UTF8String, F_OK)) {
		urlScheme = @"apple-magnifier://enable-jit?bundle-id=%@";
	} else if (self.certificatePassword) {
		tries = 2;
		urlScheme = [NSString stringWithFormat:@"%@://geode-relaunch", lcAppUrlScheme];
	} else if ([application canOpenURL:[NSURL URLWithString:@"sidestore://"]]) {
		urlScheme = @"sidestore://sidejit-enable?bid=%@";
	} else {
		tries = 2;
		urlScheme = [NSString stringWithFormat:@"%@://geode-relaunch", lcAppUrlScheme];
	}
	NSURL* launchURL = [NSURL URLWithString:[NSString stringWithFormat:urlScheme, lcMainBundle.bundleIdentifier]];

	if ([application canOpenURL:launchURL]) {
		//[UIApplication.sharedApplication suspend];
		for (int i = 0; i < tries; i++) {
			[application openURL:launchURL options:@{} completionHandler:^(BOOL b) { exit(0); }];
		}
		return YES;
	}
	return NO;
}

+ (BOOL)askForJIT {
	NSString* sideJITServerAddress = [lcUserDefaults objectForKey:@"SideJITServerAddr"];
	if (!sideJITServerAddress || ![lcUserDefaults boolForKey:@"AUTO_JIT"]) {
		if ([lcUserDefaults boolForKey:@"AUTO_JIT"]) {
			[Utils showErrorGlobal:@"JITStreamer Server Address not set." error:nil];
			return NO;
		}
		return YES;
	}
	NSString* launchJITUrlStr = [NSString stringWithFormat:@"%@/launch_app/%@", sideJITServerAddress, lcMainBundle.bundleIdentifier];
	NSURLSession* session = [NSURLSession sharedSession];
	NSURL* launchJITUrl = [NSURL URLWithString:launchJITUrlStr];
	NSURLRequest* req = [[NSURLRequest alloc] initWithURL:launchJITUrl];
	NSURLSessionDataTask* task = [session dataTaskWithRequest:req completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
		if (error) {
			return dispatch_async(dispatch_get_main_queue(), ^{
				[Utils showErrorGlobal:[NSString stringWithFormat:@"(%@/launch_app/%@) Failed to contact JITStreamer", sideJITServerAddress, lcMainBundle.bundleIdentifier]
								 error:error];
				AppLog(@"Tried connecting with %@, failed to contact JITStreamer: %@", launchJITUrlStr, error);
			});
		}
	}];
	[task resume];
	return NO;
}

+ (BOOL)launchToGuestAppWithURL:(NSURL*)url {
	NSURLComponents* components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
	if (![components.host isEqualToString:@"geode-launch"])
		return NO;

	NSString* launchBundleId = nil;
	NSString* openUrl = nil;
	// NSString* containerFolderName = nil;
	for (NSURLQueryItem* queryItem in components.queryItems) {
		if ([queryItem.name isEqualToString:@"bundle-name"]) {
			launchBundleId = queryItem.value;
		} else if ([queryItem.name isEqualToString:@"open-url"]) {
			NSData* decodedData = [[NSData alloc] initWithBase64EncodedString:queryItem.value options:0];
			openUrl = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
		} else if ([queryItem.name isEqualToString:@"container-folder-name"]) {
			// containerFolderName = queryItem.value;
		}
	}
	if (launchBundleId) {
		if (openUrl) {
			[lcUserDefaults setObject:openUrl forKey:@"launchAppUrlScheme"];
		}

		// Attempt to restart LiveContainer with the selected guest app
		[lcUserDefaults setObject:launchBundleId forKey:@"selected"];
		//[lcUserDefaults setObject:containerFolderName forKey:@"selectedContainer"];
		[lcUserDefaults setObject:@"GeometryDash" forKey:@"selectedContainer"];
		return [self launchToGuestApp];
	}
	return NO;
}

+ (void)setWebPageUrlForNextLaunch:(NSString*)urlString {
	[lcUserDefaults setObject:urlString forKey:@"webPageToOpen"];
}

+ (NSURL*)appLockPath {
	static dispatch_once_t once;
	static NSURL* infoPath;

	dispatch_once(&once, ^{ infoPath = [[LCSharedUtils appGroupPath] URLByAppendingPathComponent:@"Geode/appLock.plist"]; });
	return infoPath;
}

+ (NSURL*)containerLockPath {
	static dispatch_once_t once;
	static NSURL* infoPath;

	dispatch_once(&once, ^{ infoPath = [[LCSharedUtils appGroupPath] URLByAppendingPathComponent:@"Geode/containerLock.plist"]; });
	return infoPath;
}

+ (NSString*)getAppRunningLCSchemeWithBundleId:(NSString*)bundleId {
	NSURL* infoPath = [self appLockPath];
	NSMutableDictionary* info = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath.path];
	if (!info) {
		return nil;
	}

	for (NSString* key in info) {
		if ([bundleId isEqualToString:info[key]]) {
			if ([key isEqualToString:lcAppUrlScheme]) {
				return nil;
			}
			return key;
		}
	}

	return nil;
}

+ (NSString*)getContainerUsingLCSchemeWithFolderName:(NSString*)folderName {
	NSURL* infoPath = [self containerLockPath];
	NSMutableDictionary* info = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath.path];
	if (!info) {
		return nil;
	}

	for (NSString* key in info) {
		if ([folderName isEqualToString:info[key]]) {
			if ([key isEqualToString:lcAppUrlScheme]) {
				return nil;
			}
			return key;
		}
	}

	return nil;
}

// if you pass null then remove this lc from appLock
+ (void)setAppRunningByThisLC:(NSString*)bundleId {
	NSURL* infoPath = [self appLockPath];

	NSMutableDictionary* info = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath.path];
	if (!info) {
		info = [NSMutableDictionary new];
	}
	if (bundleId == nil) {
		[info removeObjectForKey:lcAppUrlScheme];
	} else {
		info[lcAppUrlScheme] = bundleId;
	}
	[info writeToFile:infoPath.path atomically:YES];
}

+ (void)setContainerUsingByThisLC:(NSString*)folderName {
	NSURL* infoPath = [self containerLockPath];

	NSMutableDictionary* info = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath.path];
	if (!info) {
		info = [NSMutableDictionary new];
	}
	if (folderName == nil) {
		[info removeObjectForKey:lcAppUrlScheme];
	} else {
		info[lcAppUrlScheme] = folderName;
	}
	[info writeToFile:infoPath.path atomically:YES];
}

+ (void)removeAppRunningByLC:(NSString*)LCScheme {
	NSURL* infoPath = [self appLockPath];

	NSMutableDictionary* info = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath.path];
	if (!info) {
		return;
	}
	[info removeObjectForKey:LCScheme];
	[info writeToFile:infoPath.path atomically:YES];
}

+ (void)removeContainerUsingByLC:(NSString*)LCScheme {
	NSURL* infoPath = [self containerLockPath];

	NSMutableDictionary* info = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath.path];
	if (!info) {
		return;
	}
	[info removeObjectForKey:LCScheme];
	[info writeToFile:infoPath.path atomically:YES];
}

// move app data to private folder to prevent 0xdead10cc https://forums.developer.apple.com/forums/thread/126438
+ (void)moveSharedAppFolderBack {
	NSFileManager* fm = NSFileManager.defaultManager;
	NSURL* libraryPathUrl = [fm URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].lastObject;
	NSURL* docPathUrl = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
	NSURL* appGroupFolder = [[LCSharedUtils appGroupPath] URLByAppendingPathComponent:@"Geode"];

	NSError* error;
	NSString* sharedAppDataFolderPath = [libraryPathUrl.path stringByAppendingPathComponent:@"SharedDocuments"];
	if (![fm fileExistsAtPath:sharedAppDataFolderPath]) {
		[fm createDirectoryAtPath:sharedAppDataFolderPath withIntermediateDirectories:YES attributes:@{} error:&error];
	}
	// move all apps in shared folder back
	NSArray<NSString*>* sharedDataFoldersToMove = [fm contentsOfDirectoryAtPath:sharedAppDataFolderPath error:&error];
	for (int i = 0; i < [sharedDataFoldersToMove count]; ++i) {
		NSString* destPath = [appGroupFolder.path stringByAppendingPathComponent:[NSString stringWithFormat:@"Data/Application/%@", sharedDataFoldersToMove[i]]];
		if ([fm fileExistsAtPath:destPath]) {
			[fm moveItemAtPath:[sharedAppDataFolderPath stringByAppendingPathComponent:sharedDataFoldersToMove[i]]
						toPath:[docPathUrl.path stringByAppendingPathComponent:[NSString stringWithFormat:@"FOLDER_EXISTS_AT_APP_GROUP_%@", sharedDataFoldersToMove[i]]]
						 error:&error];

		} else {
			[fm moveItemAtPath:[sharedAppDataFolderPath stringByAppendingPathComponent:sharedDataFoldersToMove[i]] toPath:destPath error:&error];
		}
	}
}

+ (NSBundle*)findBundleWithBundleId:(NSString*)bundleId {
	NSString* docPath = [NSString stringWithFormat:@"%s/Documents", getenv("LC_HOME_PATH")];

	NSURL* appGroupFolder = nil;

	NSString* bundlePath = [NSString stringWithFormat:@"%@/Applications/%@", docPath, bundleId];
	NSBundle* appBundle = [[NSBundle alloc] initWithPath:bundlePath];
	// not found locally, let's look for the app in shared folder
	if (!appBundle) {
		appGroupFolder = [[LCSharedUtils appGroupPath] URLByAppendingPathComponent:@"Geode"];

		bundlePath = [NSString stringWithFormat:@"%@/Applications/%@", appGroupFolder.path, bundleId];
		appBundle = [[NSBundle alloc] initWithPath:bundlePath];
	}
	return appBundle;
}

+ (void)dumpPreferenceToPath:(NSString*)plistLocationTo dataUUID:(NSString*)dataUUID {
	NSFileManager* fm = [[NSFileManager alloc] init];
	NSError* error1;

	NSDictionary* preferences = [lcUserDefaults objectForKey:dataUUID];
	if (!preferences) {
		return;
	}

	[fm createDirectoryAtPath:plistLocationTo withIntermediateDirectories:YES attributes:@{} error:&error1];
	for (NSString* identifier in preferences) {
		NSDictionary* preference = preferences[identifier];
		NSString* itemPath = [plistLocationTo stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", identifier]];
		if ([preference count] == 0) {
			// Attempt to delete the file
			[fm removeItemAtPath:itemPath error:&error1];
			continue;
		}
		[preference writeToFile:itemPath atomically:YES];
	}
	[lcUserDefaults removeObjectForKey:dataUUID];
}

+ (NSString*)findDefaultContainerWithBundleId:(NSString*)bundleId {
	// find app's default container
	NSURL* appGroupFolder = [[LCSharedUtils appGroupPath] URLByAppendingPathComponent:@"Geode"];

	NSString* bundleInfoPath = [NSString stringWithFormat:@"%@/Applications/%@/LCAppInfo.plist", appGroupFolder.path, bundleId];
	NSDictionary* infoDict = [NSDictionary dictionaryWithContentsOfFile:bundleInfoPath];
	return infoDict[@"LCDataUUID"];
}

@end
