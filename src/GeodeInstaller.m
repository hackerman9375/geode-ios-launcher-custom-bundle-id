#import "GeodeInstaller.h"
#import "LCUtils/Shared.h"
#import "LCUtils/unarchive.h"
#import "Utils.h"
#import "VerifyInstall.h"
#import "components/LogUtils.h"

typedef void (^DecompressCompletion)(NSError* _Nullable error);

@interface CompareSemVer : NSObject
+ (BOOL)isVersion:(NSString*)versionA greaterThanVersion:(NSString*)versionB;
@end

@implementation CompareSemVer

+ (NSString*)normalizedVersionString:(NSString*)versionString {
	if ([versionString hasPrefix:@"v"]) {
		return [versionString substringFromIndex:1];
	}
	return versionString;
}
+ (BOOL)isVersion:(NSString*)versionA greaterThanVersion:(NSString*)versionB {
	if (versionA == nil || [versionA isEqual:@""])
		return YES;
	if (versionB == nil || [versionB isEqual:@""])
		return YES;
	NSString* normalizedA = [self normalizedVersionString:versionA];
	NSString* normalizedB = [self normalizedVersionString:versionB];
	NSArray<NSString*>* componentsA = [normalizedA componentsSeparatedByString:@"."];
	NSArray<NSString*>* componentsB = [normalizedB componentsSeparatedByString:@"."];
	NSUInteger maxCount = MAX(componentsA.count, componentsB.count);
	for (NSUInteger i = 0; i < maxCount; i++) {
		NSInteger valueA = (i < componentsA.count) ? [componentsA[i] integerValue] : 0;
		NSInteger valueB = (i < componentsB.count) ? [componentsB[i] integerValue] : 0;
		if (valueA > valueB) {
			return NO;
		}
	}
	return YES;
}

@end

@implementation GeodeInstaller {
	NSURLSessionDownloadTask* downloadTask;
}
- (void)startInstall:(RootViewController*)root ignoreRoot:(BOOL)ignoreRoot {
	if (!ignoreRoot) {
		_root = root;
	}
	_root.optionalTextLabel.text = @"launcher.status.getting-ver".loc;
	if (![[Utils getPrefs] boolForKey:@"USE_NIGHTLY"]) {
		[self setVersion];
	}

	NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:[Utils getGeodeReleaseURL]]];
	NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
	NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
		if (error) {
			return dispatch_async(dispatch_get_main_queue(), ^{
				[Utils showError:_root title:@"launcher.error.req-failed".loc error:error];
				[self.root updateState];
				AppLog(@"Error during request: %@", error);
			});
		}
		if (data) {
			NSError* jsonError;
			id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
			if (jsonError) {
				return dispatch_async(dispatch_get_main_queue(), ^{
					[Utils showError:_root title:@"launcher.error.json-failed".loc error:jsonError];
					[self.root updateState];
					AppLog(@"Error during JSON: %@", error);
				});
			}
			if ([jsonObject isKindOfClass:[NSDictionary class]]) {
				NSDictionary* jsonDict = (NSDictionary*)jsonObject;
				NSArray* assets = jsonDict[@"assets"];
				if ([assets isKindOfClass:[NSArray class]]) {
					bool foundAsset = false;
					for (NSDictionary* asset in assets) {
						if ([asset isKindOfClass:[NSDictionary class]]) {
							NSString* assetName = asset[@"name"];
							if ([assetName isKindOfClass:[NSString class]]) {
								if ([assetName hasSuffix:@"-ios.zip"]) {
									NSString* downloadURL = asset[@"browser_download_url"];
									if ([downloadURL isKindOfClass:[NSString class]]) {
										dispatch_async(dispatch_get_main_queue(), ^{
											[_root progressVisibility:NO];
											_root.optionalTextLabel.text = @"launcher.status.download-geode".loc;
											NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self
																							 delegateQueue:nil];
											downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:downloadURL]];
											[downloadTask resume];
										});
										foundAsset = true;
										break;
									}
								}
							}
						}
					}
					if (!foundAsset) {
						return dispatch_async(dispatch_get_main_queue(), ^{
							[Utils showError:_root title:@"launcher.error.download-not-found".loc error:nil];
							[self.root updateState];
						});
					}
				}
			}
		}
	}];
	[dataTask resume];
}

- (void)setVersion {
	NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:[Utils getGeodeReleaseURL]]];
	NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
	NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
		if (error) {
			AppLog(@"Error during request: %@", error);
		}
		if (data) {
			NSError* jsonError;
			id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
			if (jsonError) {
				dispatch_async(dispatch_get_main_queue(), ^{ AppLog(@"Error parsing JSON: %@", jsonError); });
			} else {
				if ([jsonObject isKindOfClass:[NSDictionary class]]) {
					NSDictionary* jsonDict = (NSDictionary*)jsonObject;
					NSString* tagName = jsonDict[@"tag_name"];
					if (tagName && [tagName isKindOfClass:[NSString class]]) {
						[Utils updateGeodeVersion:tagName];
					}
				}
			}
		}
	}];
	[dataTask resume];
}

- (void)checkUpdates:(RootViewController*)root download:(BOOL)download {
	_root = root;
	NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:[Utils getGeodeReleaseURL]]];
	NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
	NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
		if (error) {
			return dispatch_async(dispatch_get_main_queue(), ^{
				[Utils showError:_root title:@"launcher.error.req-failed".loc error:error];
				[self.root updateState];
				AppLog(@"Error during request: %@", error);
			});
		}
		if (data) {
			NSError* jsonError;
			id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
			if (jsonError) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[Utils showError:_root title:@"launcher.error.json-failed".loc error:jsonError];
					if (!download)
						dispatch_async(dispatch_get_main_queue(), ^{ [self.root updateState]; });
					AppLog(@"Error parsing JSON: %@", jsonError);
				});
			} else {
				if ([jsonObject isKindOfClass:[NSDictionary class]]) {
					NSDictionary* jsonDict = (NSDictionary*)jsonObject;
					NSString* tagName = jsonDict[@"tag_name"];
					if (tagName && [tagName isKindOfClass:[NSString class]]) {
						if ([[Utils getPrefs] boolForKey:@"USE_NIGHTLY"]) {
							// assume out of date
							dispatch_async(dispatch_get_main_queue(), ^{
								if (download) {
									AppLog(@"Geode is out of date, updating...");
									[self startInstall:nil ignoreRoot:YES];
								} else {
									root.optionalTextLabel.text = @"launcher.status.update-available".loc;
									[root.launchButton setEnabled:YES];
								}
							});
						} else {
							BOOL greaterThanVer = [CompareSemVer isVersion:tagName greaterThanVersion:[Utils getGeodeVersion]];
							AppLog(@"Latest Geode version is %@ (Currently on %@)", tagName, [Utils getGeodeVersion]);
							if (greaterThanVer) {
								if ([Utils getGeodeVersion] == nil || [[Utils getGeodeVersion] isEqual:@""]) {
									AppLog(@"Updated launcher ver!");
									[Utils updateGeodeVersion:tagName];
								}
								dispatch_async(dispatch_get_main_queue(), ^{ [self checkLauncherUpdates:_root]; });
							} else if (!greaterThanVer) {
								// assume out of date
								dispatch_async(dispatch_get_main_queue(), ^{
									if (download) {
										[Utils updateGeodeVersion:tagName];
										AppLog(@"Geode is out of date, updating...");
										[self startInstall:nil ignoreRoot:YES];
									} else {
										root.optionalTextLabel.text = @"launcher.status.update-available".loc;
										[root.launchButton setEnabled:YES];
									}
								});
							}
						}
					}
				}
			}
		}
	}];
	[dataTask resume];
}

- (void)checkLauncherUpdates:(RootViewController*)root {
	if (_root == nil) {
		_root = root;
	}
	NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:[Utils getGeodeLauncherURL]]];
	NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
	NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
		if (error) {
			return dispatch_async(dispatch_get_main_queue(), ^{
				[Utils showError:_root title:@"launcher.error.req-failed".loc error:error];
				AppLog(@"Error during request: %@", error);
			});
		}
		if (data) {
			NSError* jsonError;
			id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
			if (jsonError) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[Utils showError:_root title:@"launcher.error.json-failed".loc error:jsonError];
					AppLog(@"Error parsing JSON: %@", jsonError);
				});
			} else {
				if ([jsonObject isKindOfClass:[NSDictionary class]]) {
					NSDictionary* jsonDict = (NSDictionary*)jsonObject;
					NSString* tagName = jsonDict[@"tag_name"];
					if (tagName && [tagName isKindOfClass:[NSString class]]) {
						BOOL greaterThanVer = [CompareSemVer isVersion:tagName greaterThanVersion:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
						AppLog(@"Latest Launcher version is %@ (Currently on %@)", tagName, [[NSBundle mainBundle] infoDictionary]);
						if (!greaterThanVer) {
							// assume out of date
							dispatch_async(dispatch_get_main_queue(), ^{ [Utils showNotice:_root title:@"launcher.notice.launcher-update".loc]; });
						} else {
							dispatch_async(dispatch_get_main_queue(), ^{ [self verifyChecksum]; });
						}
					}
				}
			}
		}
	}];
	[dataTask resume];
}

- (void)verifyChecksum {
	if (_root == nil || ![VerifyInstall verifyGDInstalled])
		return;
	NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://jinx.firee.dev/gode/version.txt"]];
	NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
	NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
		if (error) {
			return dispatch_async(dispatch_get_main_queue(), ^{
				[Utils showError:_root title:@"launcher.error.req-failed".loc error:error];
				[self.root updateState];
				AppLog(@"Couldn't send request to get GD version: %@", error);
			});
		}
		if (data) {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSDictionary* gdPlist;
				if ([[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
					gdPlist = [NSDictionary dictionaryWithContentsOfFile:[[Utils getGDBundlePath] stringByAppendingPathComponent:@"GeometryJump.app/Info.plist"]];
				} else {
					gdPlist = [NSDictionary dictionaryWithContentsOfURL:[[LCPath bundlePath] URLByAppendingPathComponent:@"com.robtop.geometryjump.app/Info.plist"]];
				}
				NSString* str = [[[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				NSString* hash = gdPlist[@"CFBundleShortVersionString"];
				AppLog(@"Versions: %@ & %@", hash, str);
				if (![hash isEqualToString:str]) {
					AppLog(@"Versions don't match. Assume GD needs an update!");
					if ([[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
						[Utils showNotice:_root title:@"launcher.notice.gd-outdated".loc];
					} else {
						[Utils showNotice:_root title:@"launcher.notice.gd-update".loc];
						[[Utils getPrefs] setBool:YES forKey:@"GDNeedsUpdate"];
					}
				}
				[self.root updateState];
			});
		}
	}];
	[dataTask resume];
}

- (void)decompress:(NSString*)fileToExtract extractionPath:(NSString*)extractionPath completion:(DecompressCompletion)completion {
	AppLog(@"Starting decomp of %@ to %@", fileToExtract, extractionPath);
	[[NSFileManager defaultManager] createDirectoryAtPath:extractionPath withIntermediateDirectories:YES attributes:nil error:nil];
	int res = extract(fileToExtract, extractionPath, nil);
	if (res != 0)
		return completion([NSError errorWithDomain:@"DecompressError" code:res userInfo:nil]);
	return completion(nil);
}

// updating
- (void)URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask didFinishDownloadingToURL:(NSURL*)url {
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* docPath = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject.path;
	NSString* tweakPath = [NSString stringWithFormat:@"%@/Tweaks/Geode.ios.dylib", docPath];
	if ([[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
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
	[self decompress:url.path extractionPath:[[fm temporaryDirectory] path] completion:^(NSError* _Nullable decompError) {
		if (decompError) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[Utils showError:_root title:@"Decompressing ZIP failed" error:decompError];
				[_root updateState];
			});
			return AppLog(@"Error trying to decompress ZIP: %@", decompError);
		}
		NSError* error;
		NSURL* dylibPath = [[fm temporaryDirectory] URLByAppendingPathComponent:@"Geode.ios.dylib"];
		if ([fm fileExistsAtPath:tweakPath isDirectory:false]) {
			AppLog(@"deleting existing Geode library");
			NSError* removeError;
			[fm removeItemAtPath:tweakPath error:&removeError];
			if (removeError) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[Utils showError:_root title:@"Failed to delete old Geode library" error:removeError];
					[_root updateState];
				});
				return AppLog(@"Error trying to delete existing Geode library: %@", removeError);
			}
		}
		[fm moveItemAtPath:dylibPath.path toPath:tweakPath error:&error];
		if (error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[Utils showError:_root title:@"Failed to move Geode lib" error:error];
				[_root updateState];
			});
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			[_root progressVisibility:YES];
			[_root updateState];
		});
	}];
}

- (void)URLSession:(NSURLSession*)session
				 downloadTask:(NSURLSessionDownloadTask*)downloadTask
				 didWriteData:(int64_t)bytesWritten
			totalBytesWritten:(int64_t)totalBytesWritten
	totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
	dispatch_async(dispatch_get_main_queue(), ^{
		CGFloat progress = (CGFloat)totalBytesWritten / (CGFloat)totalBytesExpectedToWrite * 100.0;
		if (![_root progressVisible])
			return [self cancelDownload];
		[self.root barProgress:progress];
	});
}

- (void)cancelDownload {
	[downloadTask cancel];
}

// error
- (void)URLSession:(NSURLSession*)session task:(NSURLSessionTask*)task didCompleteWithError:(NSError*)error {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (error) {
			[Utils showError:_root title:@"launcher.error.download-fail-restart".loc error:error];
		}
	});
}

@end
