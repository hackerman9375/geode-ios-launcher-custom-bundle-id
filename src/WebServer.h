#import "GCDWebServer/GCDWebServer/Core/GCDWebServer.h"
#import <Foundation/Foundation.h>

@interface WebServer : NSObject
@property(nonatomic, strong) GCDWebServer* webServer;
- (void)initServer;
@end
