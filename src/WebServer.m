#import "LCUtils/LCSharedUtils.h"
#import "LCUtils/Shared.h"
#import "Utils.h"
#import "WebServer.h"
#include "src/Theming.h"
#import "src/components/LogUtils.h"

#import "GCDWebServer/GCDWebServer/Requests/GCDWebServerMultiPartFormRequest.h"
#import "GCDWebServer/GCDWebServer/Responses/GCDWebServerDataResponse.h"

extern NSBundle* gcMainBundle;

@implementation WebServer
- (void)initServer {
	if ([[Utils getPrefsGC] boolForKey:@"WEB_SERVER"]) {
		__weak WebServer* weakSelf = self;
		self.webServer = [[GCDWebServer alloc] init];

		NSString* websitePath = [gcMainBundle pathForResource:@"web" ofType:nil];

		[self.webServer addGETHandlerForBasePath:@"/" directoryPath:websitePath indexFilename:nil cacheAge:0 allowRangeRequests:YES];

		NSString* infoPlistPath;
		if ([[Utils getPrefsGC] boolForKey:@"USE_TWEAK"]) {
			infoPlistPath = [[Utils getGDBundlePath] stringByAppendingPathComponent:@"GeometryJump.app/Info.plist"];
		} else {
			if ([Utils isContainerized]) {
				infoPlistPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Info.plist"];
			} else {
				infoPlistPath = [[[LCPath bundlePath] URLByAppendingPathComponent:[Utils gdBundleName]] URLByAppendingPathComponent:@"Info.plist"].path;
			}
		}
		//[NSClassFromString(@"WebSharedClass") forceRestart];
		NSDictionary* infoDictionary = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];

		NSString* model = [[UIDevice currentDevice] localizedModel];
		NSString* systemName = [[UIDevice currentDevice] systemName];
		NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
		NSString* deviceStr = [NSString stringWithFormat:@"%@ %@ (%@,%@)", systemName, systemVersion, model, [Utils archName]];
		NSFileManager* fm = [NSFileManager defaultManager];
		[self.webServer addHandlerForMethod:@"GET" pathRegex:@"/.*\\.html" requestClass:[GCDWebServerRequest class]
							   processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
								   NSError* error = nil;
								   NSArray* files;
								   if ([Utils isContainerized]) {
									   files = [fm contentsOfDirectoryAtPath:[[LCPath docPath].path stringByAppendingString:@"/game/geode/mods/"] error:&error];
								   } else {
									   files = [fm contentsOfDirectoryAtPath:[[Utils docPath] stringByAppendingString:@"game/geode/mods/"] error:&error];
								   }
								   int modsInstalled = 0;
								   if (!error) {
									   modsInstalled = (unsigned long)[files count];
								   }
								   NSDictionary* variables = @{
									   @"container" : [Utils isContainerized] ? @"container" : @"not container",
									   @"launch" : [Utils isContainerized] ? @"Restart" : @"Launch",
									   @"host" : [NSString stringWithFormat:@"%@", weakSelf.webServer.serverURL],
									   @"version" : [NSString stringWithFormat:@"v%@", [[gcMainBundle infoDictionary] objectForKey:@"CFBundleVersion"] ?: @"N/A"],
									   @"geode" : [Utils getGeodeVersion],
									   @"gd" : [NSString stringWithFormat:@"v%@", [infoDictionary objectForKey:@"CFBundleShortVersionString"] ?: @"N/A"],
									   @"device" : deviceStr,
									   @"mods" : [NSString stringWithFormat:@"%i", modsInstalled],
								   };
								   return [GCDWebServerDataResponse responseWithHTMLTemplate:[websitePath stringByAppendingPathComponent:request.path] variables:variables];
							   }];

		[self.webServer addHandlerForMethod:@"GET" path:@"/styles.css" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
			NSString* path = [gcMainBundle pathForResource:@"styles" ofType:@"css" inDirectory:@"web"];
			NSError* error = nil;
			NSString* content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
			if (error) {
				AppLog(@"Couldn't read styles.css: %@", error);
				return [GCDWebServerDataResponse responseWithStatusCode:500];
			}
			return [GCDWebServerDataResponse responseWithData:[[content stringByReplacingOccurrencesOfString:@"%accent%" withString:[Utils colorToHex:[Theming getAccentColor]]]
																  dataUsingEncoding:NSUTF8StringEncoding]
												  contentType:@"text/css"];
		}];

		[self.webServer addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
			return [GCDWebServerResponse responseWithRedirect:[NSURL URLWithString:@"index.html" relativeToURL:request.URL] permanent:NO];
		}];
		[self.webServer addHandlerForMethod:@"POST" path:@"/launch" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
			GCDWebServerDataResponse* response = [GCDWebServerDataResponse responseWithStatusCode:200];
			if ([Utils isContainerized]) {
				[NSClassFromString(@"LCSharedUtils") relaunchApp];
				return response;
			}
			if ([[Utils getPrefsGC] boolForKey:@"MANUAL_REOPEN"] && ![[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
				[[Utils getPrefsGC] setValue:[Utils gdBundleName] forKey:@"selected"];
				[[Utils getPrefsGC] setValue:@"GeometryDash" forKey:@"selectedContainer"];
				[[Utils getPrefsGC] setBool:NO forKey:@"safemode"];
				NSFileManager* fm = [NSFileManager defaultManager];
				[fm createFileAtPath:[[LCPath docPath] URLByAppendingPathComponent:@"jitflag"].path contents:[[NSData alloc] init] attributes:@{}];
				// get around NSUserDefaults because sometimes it works and doesnt work when relaunching...
				[Utils showNoticeGlobal:@"launcher.relaunch-notice".loc];
				return response;
			}
			if ([[Utils getPrefsGC] boolForKey:@"USE_TWEAK"]) {
				[Utils tweakLaunch_withSafeMode:false];
				return response;
			}
			NSString* openURL = [NSString stringWithFormat:@"geode://launch"];
			NSURL* url = [NSURL URLWithString:openURL];
			if ([[NSClassFromString(@"UIApplication") sharedApplication] canOpenURL:url]) {
				[[NSClassFromString(@"UIApplication") sharedApplication] openURL:url options:@{} completionHandler:nil];
				return response;
			};
			return response;
		}];
		[self.webServer addHandlerForMethod:@"POST" path:@"/stop" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
			GCDWebServerDataResponse* response = [GCDWebServerDataResponse responseWithStatusCode:200];
			[weakSelf.webServer stop];
			return response;
		}];

		[self.webServer addHandlerForMethod:@"GET" path:@"/logs" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
			if (![Utils isContainerized]) {
				GCDWebServerDataResponse* response = [GCDWebServerDataResponse responseWithStatusCode:400];
				return response;
			} else {
				NSURL* file = [Utils pathToMostRecentLogInDirectory:[[LCPath docPath].path stringByAppendingString:@"/game/geode/logs/"]];
				NSError* error = nil;
				NSString* content = [NSString stringWithContentsOfFile:file.path encoding:NSUTF8StringEncoding error:&error];
				if (error) {
					AppLog(@"Couldn't read the latest log: %@", error);
					return [GCDWebServerDataResponse responseWithStatusCode:500];
				}
				GCDWebServerDataResponse* response = [GCDWebServerDataResponse responseWithData:(NSData*)[content dataUsingEncoding:NSUTF8StringEncoding]
																					contentType:@"text/plain"];
				return response;
			}
		}];
		[self.webServer addHandlerForMethod:@"POST" path:@"/upload" requestClass:[GCDWebServerMultiPartFormRequest class]
							   processBlock:^GCDWebServerResponse*(GCDWebServerMultiPartFormRequest* request) {
								   GCDWebServerMultiPartFile* file = [request firstFileForControlName:@"file"];
								   if (!file)
									   return [GCDWebServerDataResponse responseWithStatusCode:400];
								   AppLog(@"[Server] Received request to upload %@", file.fileName);
								   NSURL* path;
								   if ([Utils isContainerized]) {
									   path = [NSURL fileURLWithPath:[[LCPath docPath].path stringByAppendingString:@"/game/geode/mods/"]];
								   } else {
									   path = [NSURL fileURLWithPath:[[Utils docPath] stringByAppendingString:@"game/geode/mods/"]];
								   }
								   NSURL* destinationURL = [path URLByAppendingPathComponent:file.fileName];
								   if ([file.fileName isEqualToString:@"Geode.ios.dylib"]) {
									   if ([Utils isContainerized]) {
										   return [GCDWebServerDataResponse responseWithStatusCode:400];
									   }
									   AppLog(@"[Server] Getting Geode dylib path...");
									   NSString* docPath = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject.path;
									   NSString* tweakPath = [NSString stringWithFormat:@"%@/Tweaks/Geode.ios.dylib", docPath];
									   if ([[Utils getPrefsGC] boolForKey:@"USE_TWEAK"]) {
										   NSString* applicationSupportDirectory = [[Utils getGDDocPath] stringByAppendingString:@"Library/Application Support"];
										   if (applicationSupportDirectory != nil) {
											   // https://github.com/geode-catgirls/geode-inject-ios/blob/meow/src/geode.m
											   NSString* geode_dir = [applicationSupportDirectory stringByAppendingString:@"/GeometryDash/game/geode"];
											   NSString* geode_lib = [geode_dir stringByAppendingString:@"/Geode.ios.dylib"];
											   bool is_dir;
											   NSFileManager* fm = [NSFileManager defaultManager];
											   if (![fm fileExistsAtPath:geode_dir isDirectory:&is_dir]) {
												   AppLog(@"mrow creating geode dir !!");
												   if (![fm createDirectoryAtPath:geode_dir withIntermediateDirectories:YES attributes:nil error:NULL]) {
													   AppLog(@"mrow failed to create folder!!");
												   }
											   }
											   tweakPath = geode_lib;
										   }
									   }
									   destinationURL = [NSURL fileURLWithPath:tweakPath];
								   }
								   NSError* error = nil;
								   if ([fm fileExistsAtPath:destinationURL.path]) {
									   [fm removeItemAtURL:destinationURL error:&error];
									   if (error) {
										   AppLog(@"[Server] Couldn't replace file: %@", error);
										   return [GCDWebServerDataResponse responseWithStatusCode:500];
									   }
								   }
								   if ([fm moveItemAtPath:file.temporaryPath toPath:destinationURL.path error:&error]) {
									   AppLog(@"[Server] Uploaded file!");
									   return [GCDWebServerDataResponse responseWithText:[NSString stringWithFormat:@"File %@ uploaded successfully", file.fileName]];
								   } else {
									   NSLog(@"[Server] Error saving file: %@", error);
									   return [GCDWebServerDataResponse responseWithStatusCode:500];
								   }
							   }];
		[self.webServer startWithPort:8080 bonjourName:nil];
		AppLog(@"Started server: %@", self.webServer.serverURL);
	}
}
@end
