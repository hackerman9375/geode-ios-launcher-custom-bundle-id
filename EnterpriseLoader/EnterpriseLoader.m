#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <objc/runtime.h>
#include "../src/LCUtils/unarchive.h"

BOOL loadGeode = YES;

void exitNotice(NSString * msg) {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notice" message:msg preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *ok = [UIAlertAction
			actionWithTitle:@"OK"
					  style:UIAlertActionStyleDefault
					handler:^(UIAlertAction * _Nonnull action) {
						exit(0);
					}];
		[alert addAction:ok];
		id anyScene = [UIApplication.sharedApplication.connectedScenes allObjects].firstObject;
		UIWindowScene *scene = [anyScene isKindOfClass:UIWindowScene.class] ? anyScene : nil;
		UIWindow *alertWindow;
		if (scene) {
			alertWindow = [[UIWindow alloc] initWithWindowScene:scene];
		} else {
			alertWindow = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
		}
		alertWindow.windowLevel = UIWindowLevelAlert + 1;
		UIViewController *vc = [UIViewController new];
		alertWindow.rootViewController = vc;
		[alertWindow makeKeyAndVisible];
		[vc presentViewController:alert animated:YES completion:nil];
	});
}

@implementation NSObject(modif_AppController)
- (void)moveModOutOfBundle:(BOOL)omods modsBinDir:(NSArray<NSString*>*)modsBinDir {
	NSLog(@"[EnterpriseLoader] moveModOutOfBundle(%d)", omods);
	NSFileManager* fm = [NSFileManager defaultManager];
	NSURL* docDir = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
	NSURL* gameDir = [docDir URLByAppendingPathComponent:@"game/geode"];
	NSURL* unzippedDir = [gameDir URLByAppendingPathComponent:@"unzipped"];
	NSString* bundleMods = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"mods"];
	if (omods) {
		//bundleMods = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"o_mods"];
	}
	NSURL* unzippedBinDir = [unzippedDir URLByAppendingPathComponent:@"binaries"];
	if ([fm fileExistsAtPath:bundleMods isDirectory:nil]) {
		if ([fm fileExistsAtPath:unzippedBinDir.path isDirectory:nil] && !omods) {
			NSLog(@"[EnterpriseLoader] Removing binaries dir");
			[fm removeItemAtPath:unzippedBinDir.path error:nil];
			return;
		}
		NSLog(@"[EnterpriseLoader] moveModOutOfBundle s1");
		if (!modsBinDir) {
			NSLog(@"[EnterpriseLoader] Error retrieving files in bundle mods dir");
		} else {
			NSLog(@"[EnterpriseLoader] Creating directories if they don't exist...");
			if (![fm fileExistsAtPath:unzippedDir.path isDirectory:nil]) {
				[fm createDirectoryAtURL:unzippedDir withIntermediateDirectories:YES attributes:nil error:nil];
			}
			if (![fm fileExistsAtPath:unzippedBinDir.path isDirectory:nil]) {
				[fm createDirectoryAtURL:unzippedBinDir withIntermediateDirectories:YES attributes:nil error:nil];
			}
			NSLog(@"[EnterpriseLoader] Checking mod binaries dir...");
			for (NSString *file in modsBinDir) {
				NSURL *srcURL = [[NSURL fileURLWithPath:bundleMods isDirectory:YES] URLByAppendingPathComponent:file];
				NSURL *destURL = [unzippedBinDir URLByAppendingPathComponent:file];
				if ([fm fileExistsAtPath:destURL.path]) {
					[fm removeItemAtURL:destURL error:nil];
				}
				[fm copyItemAtURL:srcURL toURL:destURL error:nil];
			}
			/*if (omods) {
				NSLog(@"[EnterpriseLoader] o_mods -> oo_mods");
				[fm moveItemAtPath:bundleMods toPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"oo_mods"] error:nil];
			} else {
				NSLog(@"[EnterpriseLoader] mods -> o_mods");
				[fm moveItemAtPath:bundleMods toPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"o_mods"] error:nil];
			}*/
		}
	}
}
- (void)reallyLaunch:(UIApplication*)application {

}
- (BOOL)rly_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSLog(@"[EnterpriseLoader] application:didFinishLaunchingWithOptions swizzled!");
	NSFileManager* fm = [NSFileManager defaultManager];
	NSURL* docDir = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
	NSURL* gameDir = [docDir URLByAppendingPathComponent:@"game/geode"];
	NSURL* unzippedDir = [gameDir URLByAppendingPathComponent:@"unzipped"];
	
	BOOL firstTimeLoad = NO;
	// very verbose
	if ([fm fileExistsAtPath:gameDir.path]) {
		NSLog(@"[EnterpriseLoader] gameDir exists");
		if ([fm fileExistsAtPath:unzippedDir.path]) {
			NSLog(@"[EnterpriseLoader] unzipped exists");
			if (![fm fileExistsAtPath:[unzippedDir URLByAppendingPathComponent:@"launch-args.txt"].path]) {
				loadGeode = NO;
				NSLog(@"[EnterpriseLoader] launch-args.txt doesn't exist! assuming haven't launched with launcher...");
			}
		}
	} else {
		firstTimeLoad = YES;
	}
	if (loadGeode && !firstTimeLoad) {
		NSLog(@"[EnterpriseLoader] Geode will load");
		NSString *bbUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
		NSString* sfBdPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"sf.bd"];
		NSString* sfBd = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:sfBdPath] encoding:NSUTF8StringEncoding error:nil];
		if (sfBd == nil) {
			exitNotice(@"sf missing. Please reinstall the helper.");
			return YES;
		}
		if (![bbUID isEqualToString:bbUID]) {
			exitNotice(@"Unable to verify. Please ensure both the launcher and helper are signed with the same certificate and installed with the same method.");
			return YES;
		}
		[self moveModOutOfBundle:YES modsBinDir:[fm contentsOfDirectoryAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"mods"] error:nil]];
		NSLog(@"[EnterpriseLoader] dlopen(\"@executable_path/Geode.ios.dylib\", RTLD_LAZY | RTLD_GLOBAL)");
		void *handle = dlopen("@executable_path/Geode.ios.dylib", RTLD_LAZY | RTLD_GLOBAL);
		const char *error = dlerror();
		if (handle) {
			NSLog(@"[EnterpriseLoader] Loaded Geode.ios.dylib");
		} else if (error) {
			NSLog(@"[EnterpriseLoader] Failed to dlopen Geode.ios.dylib: %s", error);
		} else {
			NSLog(@"[EnterpriseLoader] Failed to dlopen Geode.ios.dylib: Unknown error because dlerror() returns NULL");
		}
	} else if (!loadGeode && !firstTimeLoad) {
		NSLog(@"[EnterpriseLoader] Geode won't load");
		exitNotice(@"You must launch the helper with the launcher.");
		return YES;
	} else {
		NSLog(@"[EnterpriseLoader] First time load, force loading Geode...");
		void *handle = dlopen("@executable_path/Geode.ios.dylib", RTLD_LAZY | RTLD_GLOBAL);
		const char *error = dlerror();
		if (handle) {
			NSLog(@"[EnterpriseLoader] Loaded Geode.ios.dylib");
		} else if (error) {
			NSLog(@"[EnterpriseLoader] Failed to dlopen Geode.ios.dylib: %s", error);
		} else {
			NSLog(@"[EnterpriseLoader] Failed to dlopen Geode.ios.dylib: Unknown error because dlerror() returns NULL");
		}
	}
	return [self rly_application:application didFinishLaunchingWithOptions:nil];
}
- (BOOL)rly_application:(UIApplication*)application openURL:(nonnull NSURL*)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey, id>*)options {
	if ([url.scheme isEqualToString:@"geode-helper"]) {
		NSLog(@"[EnterpriseLoader] Launched with %@", url);
		NSFileManager* fm = [NSFileManager defaultManager];
		NSURL* docDir = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
		if (!docDir) return NO;
		if ([url.host isEqualToString:@"launchent"]) {
			[self reallyLaunch:application];
		}
		if ([url.host isEqualToString:@"launch"]) {
			NSURLComponents* components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
			for (NSURLQueryItem* item in components.queryItems) {
				if ([item.name isEqualToString:@"args"]) {
					NSMutableString *encodedUrl = [item.value mutableCopy];
					[encodedUrl replaceOccurrencesOfString:@"-" withString:@"+" options:0 range:NSMakeRange(0, encodedUrl.length)];
					[encodedUrl replaceOccurrencesOfString:@"_" withString:@"/" options:0 range:NSMakeRange(0, encodedUrl.length)];
					while (encodedUrl.length % 4 != 0) {
						[encodedUrl appendString:@"="];
					}
					NSData* decodedData = [[NSData alloc] initWithBase64EncodedString:encodedUrl options:0];
					if (decodedData) {
						NSString* decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
						NSString* geode_env = [docDir.path stringByAppendingString:@"/game/geode/unzipped/launch-args.txt"];
						[fm createFileAtPath:geode_env contents:[decodedString dataUsingEncoding:NSUTF8StringEncoding] attributes:@{}];
					}
				}
			}
			[self moveModOutOfBundle:NO modsBinDir:nil];
			NSURL *url = [NSURL URLWithString:@"geode://launchent"];
			if ([[UIApplication sharedApplication] canOpenURL:url]) {
				for (int i = 0; i < 1; i++) {
					[application openURL:url options:@{} completionHandler:^(BOOL b) { exit(0); }];
				}
			} else {
				NSLog(@"[EnterpriseLoader] Couldn't open %@. Aborting!", url);
				abort();
				return NO;
			}
		} else if ([url.host isEqualToString:@"check"]) {
			BOOL safeMode = NO;
			BOOL dontCallBack = NO;
			NSString* uri = @"geode";

			NSString* decodedString;
			NSString* geode_env;

			NSURLComponents* components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
			for (NSURLQueryItem* item in components.queryItems) {
				if ([item.name isEqualToString:@"safe"]) {
					if ([item.value isEqualToString:@"1"]) {
						safeMode = YES;
					}
				} else if ([item.name isEqualToString:@"callback"]) {
					uri = item.value;
				} else if ([item.name isEqualToString:@"args"]) {
					NSMutableString *encodedUrl = [item.value mutableCopy];
					[encodedUrl replaceOccurrencesOfString:@"-" withString:@"+" options:0 range:NSMakeRange(0, encodedUrl.length)];
					[encodedUrl replaceOccurrencesOfString:@"_" withString:@"/" options:0 range:NSMakeRange(0, encodedUrl.length)];
					while (encodedUrl.length % 4 != 0) {
						[encodedUrl appendString:@"="];
					}
					NSData* decodedData = [[NSData alloc] initWithBase64EncodedString:encodedUrl options:0];
					if (decodedData) {
						decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
						geode_env = [docDir.path stringByAppendingString:@"/game/geode/unzipped/launch-args.txt"];
					}
				} else if ([item.name isEqualToString:@"dontCallback"]) {
					dontCallBack = YES;
				}
			}
			NSString *zipPath = [[fm temporaryDirectory] URLByAppendingPathComponent:@"data_tmp.zip"].path;
			if ([fm fileExistsAtPath:zipPath]) {
				[fm removeItemAtPath:zipPath error:nil];
			}
			BOOL force = NO;
			int result = compressEnt(docDir.path, zipPath, &force);
			if (result != 0) {
				NSLog(@"[EnterpriseLoader] Couldn't create zip file: %d", result);
				return NO;
			}
			NSLog(@"[EnterpriseLoader] Finish compressing");
			if (decodedString && geode_env && !force) {
				[fm createFileAtPath:geode_env contents:[decodedString dataUsingEncoding:NSUTF8StringEncoding] attributes:@{}];
			}
			dispatch_async(dispatch_get_main_queue(), ^{
				NSData *zipData = [NSData dataWithContentsOfFile:zipPath];
				NSMutableString *encoded = [[zipData base64EncodedStringWithOptions:0] mutableCopy];
				[encoded replaceOccurrencesOfString:@"+" withString:@"-" options:0 range:NSMakeRange(0, encoded.length)];
				[encoded replaceOccurrencesOfString:@"/" withString:@"_" options:0 range:NSMakeRange(0, encoded.length)];
				while ([encoded hasSuffix:@"="]) {
					[encoded deleteCharactersInRange:NSMakeRange(encoded.length - 1, 1)];
				}
				NSString *encodedParam = [encoded stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
				NSString *urlString = [NSString stringWithFormat:@"%@://import?data=%@%@%@%@",
					uri,
					encodedParam,
					(force) ? @"&force=1" : @"",
					(safeMode) ? @"safeMode=1" : @"",
					(dontCallBack) ? @"dontCallback=1" : @""
				];
				NSLog(@"[EnterpriseLoader] Moving mods out of bundle...");
				[self moveModOutOfBundle:NO modsBinDir:nil];
				NSLog(@"[EnterpriseLoader] Moved mods out of bundle!");
				NSURL *url = [NSURL URLWithString:urlString];
				if ([[UIApplication sharedApplication] canOpenURL:url]) {
					for (int i = 0; i < 1; i++) {
						[application openURL:url options:@{} completionHandler:^(BOOL b) { exit(0); }];
					}
				} else {
					NSLog(@"[EnterpriseLoader] Couldn't open %@. Aborting!", url);
					abort();
				}
			});
		}
		return YES;
	}
	return [self rly_application:application openURL:url options:options];
}
@end

__attribute__((constructor))
static void EnterpriseLoaderConstructor() {
	NSLog(@"[EnterpriseLoader] Init");
	// we swizzle because this is too early...
	Class appCtrl = NSClassFromString(@"AppController");
	if (appCtrl) {
		{
			SEL orig = @selector(application:didFinishLaunchingWithOptions:);
			SEL swizzled = @selector(rly_application:didFinishLaunchingWithOptions:);
			Method origMethod = class_getInstanceMethod(appCtrl, orig);
			Method swzMethod  = class_getInstanceMethod([NSObject class], swizzled);
			if (origMethod && swzMethod) {
				class_addMethod(appCtrl, swizzled, method_getImplementation(swzMethod), method_getTypeEncoding(swzMethod));
				method_exchangeImplementations(origMethod, class_getInstanceMethod(appCtrl, swizzled));
				NSLog(@"[EnterpriseLoader] Swizzling (AppController) application:didFinishLaunchingWithOptions");
			}
		}
		{
			SEL orig = @selector(application:openURL:options:);
			SEL swizzled = @selector(rly_application:openURL:options:);
			Method origMethod = class_getInstanceMethod(appCtrl, orig);
			Method swzMethod  = class_getInstanceMethod([NSObject class], swizzled);
			if (!class_getInstanceMethod(appCtrl, orig)) {
				class_addMethod(appCtrl, orig, method_getImplementation(swzMethod), method_getTypeEncoding(swzMethod));
				NSLog(@"[EnterpriseLoader] (addMethod) Swizzling (AppController) application:openURL");
			} else if (origMethod && swzMethod) {
				class_addMethod(appCtrl, swizzled, method_getImplementation(swzMethod), method_getTypeEncoding(swzMethod));
				method_exchangeImplementations(origMethod, class_getInstanceMethod(appCtrl, swizzled));
				NSLog(@"[EnterpriseLoader] Swizzling (AppController) application:openURL");
			} else {
				NSLog(@"[EnterpriseLoader] Couldn't swizzle (AppController) application:openURL");
			}
		}
	}
}
