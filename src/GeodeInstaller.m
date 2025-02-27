#import "GeodeInstaller.h"
#import "Utils.h"

// ai
@interface CompareSemVer : NSObject
+ (BOOL)isVersion:(NSString *)versionA greaterThanVersion:(NSString *)versionB;
@end

@implementation CompareSemVer

+ (NSString *)normalizedVersionString:(NSString *)versionString {
    if ([versionString hasPrefix:@"v"]) {
        return [versionString substringFromIndex:1];
    }
    return versionString;
}
+ (BOOL)isVersion:(NSString *)versionA greaterThanVersion:(NSString *)versionB {
    if (versionA == nil || [versionA isEqual:@""]) return YES;
    if (versionB == nil || [versionB isEqual:@""]) return YES;
    NSString *normalizedA = [self normalizedVersionString:versionA];
    NSString *normalizedB = [self normalizedVersionString:versionB];
    NSArray<NSString *> *componentsA = [normalizedA componentsSeparatedByString:@"."];
    NSArray<NSString *> *componentsB = [normalizedB componentsSeparatedByString:@"."];
    NSUInteger maxCount = MAX(componentsA.count, componentsB.count);
    for (NSUInteger i = 0; i < maxCount; i++) {
        NSInteger valueA = (i < componentsA.count) ? [componentsA[i] integerValue] : 0;
        NSInteger valueB = (i < componentsB.count) ? [componentsB[i] integerValue] : 0;
        if (valueA >= valueB) {
            return YES;
        } else if (valueA < valueB) {
            return NO;
        }
    }
    return NO;
}

@end

@implementation GeodeInstaller {
    NSURLSessionDownloadTask *downloadTask;
}
- (void)startInstall:(RootViewController *)root ignoreRoot:(BOOL)ignoreRoot {
    if (!ignoreRoot) {
        _root = root;
    }
    _root.optionalTextLabel.text = @"Downloading Geode...";
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:@"http://192.168.200.213:3000/Geode.ios.dylib"]];
    [downloadTask resume];
}

/*
private const val GITHUB_API_BASE = "https://api.github.com"
        private const val GITHUB_API_HEADER = "X-GitHub-Api-Version"
        private const val GITHUB_API_VERSION = "2022-11-28"

        private const val GITHUB_RATELIMIT_REMAINING = "x-ratelimit-remaining"
        private const val GITHUB_RATELIMIT_RESET = "x-ratelimit-reset"

        private const val GEODE_API_BASE = "https://api.geode-sdk.org/v1"
*/
- (void)checkUpdates:(RootViewController*)root download:(BOOL)download {
    _root = root;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[Utils getGeodeReleaseURL]]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            return dispatch_async(dispatch_get_main_queue(), ^{
                [Utils showError:_root title:@"Request failed" error:error];
                [self.root updateState];
                NSLog(@"Error during request: %@", error);
            });
        }
        if (data) {
            NSError *jsonError;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [Utils showError:_root title:@"JSON parsing failed" error:jsonError];
                    if (!download) dispatch_async(dispatch_get_main_queue(), ^{
                        [self.root updateState];
                    });
                    NSLog(@"Error parsing JSON: %@", jsonError);
                });
            } else {
                if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *jsonDict = (NSDictionary *)jsonObject;
                    NSString *tagName = jsonDict[@"tag_name"];
                    if (tagName && [tagName isKindOfClass:[NSString class]]) {
                        BOOL greaterThanVer = [CompareSemVer isVersion:tagName greaterThanVersion:[Utils getGeodeVersion]];
                        if (greaterThanVer) {
                            if ([Utils getGeodeVersion] == nil || [[Utils getGeodeVersion] isEqual:@""]) {
                                NSLog(@"Updated launcher ver!");
                                [Utils updateGeodeVersion:tagName];
                            }
                            // yeah this makes literally no sense
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.root updateState];
                            });
                        } else if (!greaterThanVer) {
                            // assume out of date 
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (download) {
                                    [Utils updateGeodeVersion:tagName];
                                    NSLog(@"Geode is out of date, updating...");
                                    [root progressVisibility:NO];
                                    [self startInstall:nil ignoreRoot:YES];
                                } else {
                                    root.optionalTextLabel.text = @"Update is available!";
                                    [root.launchButton setEnabled:YES];
                                }
                            });
                        }
                    }
                }
            }
        }
    }];
    [dataTask resume];
}

// updating
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    [_root progressVisibility:YES];
    [_root updateState];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat progress = (CGFloat)totalBytesWritten / (CGFloat)totalBytesExpectedToWrite * 100.0;
        [self.root barProgress:progress];
    });
}

// error
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            // something must have horribly gone wrong for this to happen...
            [Utils showError:_root title:@"Download failed, please restart the app" error:error];
        }
    });
}

@end
