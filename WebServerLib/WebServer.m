@import Foundation;

#import "src/components/LogUtils.h"
#import "src/WebServer.h"
#define WebAppLog(x...) [NSClassFromString(@"LogUtils") log:x];

__attribute__((constructor))
static void WebServerConstructor() {
    WebAppLog(@"WebServer Library Loaded!");
    [[NSClassFromString(@"WebServer") alloc] initServer];
}

