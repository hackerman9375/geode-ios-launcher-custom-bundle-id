#import "FoundationPrivate.h"
#import "GCSharedUtils.h"
#import "fishhook/fishhook.h"
#import "utils.h"
#include <UIKit/UIKit.h>
#include <dlfcn.h>

// TODO: this is not implemented fully yet

static int (*orig_UIApplicationMain)(int, char*[], void*, NSString*) = NULL;

int hook_UIApplicationMain(int argc, char* argv[], void* principalClass, NSString* delegateClass) {
	// delegateClass = @"AppDelegate"; // launcher
	// delegateClass = @"AppController"; // gd
	return orig_UIApplicationMain(argc, argv, principalClass, delegateClass);
}

void UIAGuestHooksInit() {
	void* uikitHandle = dlopen("/System/Library/Frameworks/UIKit.framework/UIKit", RTLD_GLOBAL);
	void* uiApplicationMainAddr = dlsym(uikitHandle, "UIApplicationMain");
	if (uiApplicationMainAddr) {
		rebind_symbols((struct rebinding[1]){ { "UIApplicationMain", hook_UIApplicationMain, (void*)&orig_UIApplicationMain } }, 1);
	}
}
