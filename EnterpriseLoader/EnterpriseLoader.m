#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <objc/runtime.h>

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

@implementation NSObject (MyDylib)
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
		//NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.geode.launcher"];
		//NSString *bbUID2 = [shared objectForKey:@"BB"];
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
		NSLog(@"[EnterpriseLoader] pass validation");
		NSString* bundleMods = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"mods"];
		NSURL* unzippedBinDir = [unzippedDir URLByAppendingPathComponent:@"binaries"];
		NSError* err;
		if ([fm fileExistsAtPath:bundleMods isDirectory:nil]) {
			NSArray<NSString*>* modsBinDir = [fm contentsOfDirectoryAtPath:bundleMods error:&err];		
			if (err || !modsBinDir) {
				NSLog(@"[EnterpriseLoader] Error retrieving files in bundle mods dir: %@", err);
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
				NSLog(@"[EnterpriseLoader] mods -> o_mods");
				[fm moveItemAtPath:bundleMods toPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"o_mods"] error:nil];
			}
		}
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
	return [self rly_application:application didFinishLaunchingWithOptions:launchOptions];
}
@end

__attribute__((constructor))
static void EnterpriseLoaderConstructor() {
	NSLog(@"[EnterpriseLoader] Init");
	// we swizzle because this is too early...
	Class appCtrl = NSClassFromString(@"AppController");
	if (appCtrl) {
		NSLog(@"[EnterpriseLoader] Swizzling (AppController) application:didFinishLaunchingWithOptions");
		SEL orig = @selector(application:didFinishLaunchingWithOptions:);
		SEL swizzled = @selector(rly_application:didFinishLaunchingWithOptions:);
		Method origMethod = class_getInstanceMethod(appCtrl, orig);
		Method swzMethod  = class_getInstanceMethod([NSObject class], swizzled);
		if (origMethod && swzMethod) {
			class_addMethod(appCtrl, swizzled, method_getImplementation(swzMethod), method_getTypeEncoding(swzMethod));
			method_exchangeImplementations(origMethod, class_getInstanceMethod(appCtrl, swizzled));
		}
	}
}
