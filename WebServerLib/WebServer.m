@import Foundation;

#import "src/components/LogUtils.h"
#import "src/WebServer.h"

__attribute__((constructor))
static void WebServerConstructor() {
	[NSClassFromString(@"LogUtils") log:@"WebServer Library Loaded!"];
	[[NSClassFromString(@"WebServer") alloc] initServer];
}
