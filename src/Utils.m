#import "Utils.h"
#import "components/LogUtils.h"
#import "LCUtils/Shared.h"
#import <CommonCrypto/CommonCrypto.h>
#import <mach-o/arch.h>
#import <Security/Security.h>
#import <Foundation/Foundation.h>

BOOL checkedSandboxed = NO;
BOOL sandboxValue = NO;
NSString *gdBundlePath = nil;
NSString *gdDocPath = nil;

@implementation Utils
+ (NSString*)launcherBundleName {
    return @"com.geode.launcher";
}
+ (NSString*)gdBundleName {
    return @"com.robtop.geometryjump.app";
    //return @"GeometryDash";
}
+ (BOOL)isJailbroken {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/var/jb"] || access("/var/mobile", R_OK) == 0;
}
+ (void)increaseLaunchCount {
    NSInteger currentCount = [[Utils getPrefs] integerForKey:@"LAUNCH_COUNT"];
    if (!currentCount) currentCount = 1;
    [[Utils getPrefs] setInteger:(currentCount + 1) forKey:@"LAUNCH_COUNT"];
}

+ (NSString*)getGeodeVersion {
    NSString *verTag = [[Utils getPrefs] stringForKey:@"CURRENT_VERSION_TAG"];
    return (verTag) ? verTag : @"Geode not installed";
}

+ (void)updateGeodeVersion:(NSString *)newVer {
    NSUserDefaults *userDefaults = [Utils getPrefs];
    [userDefaults setObject:newVer forKey:@"CURRENT_VERSION_TAG"];
    [userDefaults synchronize]; // apple says this is not recommended... DOES ANYWAYS
}

+ (NSString*)getGeodeReleaseURL {
    //return @"http://192.168.200.1:38000";
    return @"https://api.github.com/repos/geode-sdk/geode/releases/latest";
}
+ (NSString*)getGeodeLauncherURL {
    return @"https://api.github.com/repos/geode-sdk/ios-launcher/releases/latest";
}

// ai generated because i cant figure this out
+ (UIImageView *)imageViewFromPDF:(NSString *)pdfName {
    NSURL *pdfURL = [[NSBundle mainBundle] URLForResource:pdfName withExtension:@"pdf"];
    if (!pdfURL) {
        return nil;
    }

    CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithURL((__bridge CFURLRef)pdfURL);
    if (!pdfDocument) {
        return nil;
    }

    CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfDocument, 1); // Get the first page
    if (!pdfPage) {
        CGPDFDocumentRelease(pdfDocument);
        return nil;
    }

    CGRect pageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
    UIGraphicsBeginImageContext(pageRect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Draw the PDF page into the context
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0, pageRect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawPDFPage(context, pdfPage);
    CGContextRestoreGState(context);

    // Create the UIImage from the context
    UIImage *pdfImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Release the PDF document
    CGPDFDocumentRelease(pdfDocument);

    // Create and return the UIImageView
    UIImageView *imageView = [[UIImageView alloc] initWithImage:pdfImage];
    return imageView;
}
+ (NSURL *)pathToMostRecentLogInDirectory:(NSString *)directoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;

    // Get all files in directory
    NSArray<NSURL *> *files = [fileManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:directoryPath]
                                         includingPropertiesForKeys:@[NSURLCreationDateKey]
                                                            options:NSDirectoryEnumerationSkipsHiddenFiles
                                                              error:&error];

    if (error) {
        AppLog(@"[Geode] Couldn't read %@, Error reading directory: %@", directoryPath, error.localizedDescription);
        return nil;
    }

    // Filter and sort log files
    NSArray *logFiles = [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension == 'log'"]];

    logFiles = [logFiles sortedArrayUsingComparator:^NSComparisonResult(NSURL *file1, NSURL *file2) {
        // Get creation dates
        NSDate *date1, *date2;
        [file1 getResourceValue:&date1 forKey:NSURLCreationDateKey error:nil];
        [file2 getResourceValue:&date2 forKey:NSURLCreationDateKey error:nil];

        // Reverse chronological order
        return [date2 compare:date1];
    }];

    return logFiles.firstObject;
}
+ (BOOL)canAccessDirectory:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path isDirectory:nil];
}
+ (NSString*)getGDDocPath {
    // me when performance
    if (gdDocPath != nil) return gdDocPath;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError* err;
    NSArray *dirs = [fm contentsOfDirectoryAtPath:@"/var/mobile/Containers/Data/Application" error:&err];
    if (err) {
        // assume we arent on jb or trollstore
        AppLog(@"[Geode] Couldn't get doc path %@", err);
        return nil;
    }
    // probably the most inefficient way of getting a bundle id, i need to figure out another way of doing this because this is just bad...
    for (NSString *dir in dirs) {
        NSString *checkPrefsA = [NSString stringWithFormat:@"/var/mobile/Containers/Data/Application/%@/Library/HTTPStorages/com.robtop.geometryjump", dir];
        NSString *checkPrefsB = [NSString stringWithFormat:@"/var/mobile/Containers/Data/Application/%@/tmp/com.robtop.geometryjump-Inbox", dir];
        if ([fm fileExistsAtPath:checkPrefsA isDirectory:nil] || [fm fileExistsAtPath:checkPrefsB isDirectory:nil]) {
            gdDocPath = [NSString stringWithFormat:@"/var/mobile/Containers/Data/Application/%@/", dir];
            return gdDocPath;
        }
    }
    
    return nil;
}

+ (NSString*)getGDBinaryPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError* err;
    NSArray *dirs = [fm contentsOfDirectoryAtPath:@"/var/containers/Bundle/Application" error:&err];
    if (err) {
        // assume we arent on jb or trollstore
        return nil;
    }
    // probably the most inefficient way of getting a bundle id, i need to figure out another way of doing this because this is just bad...
    for (NSString *dir in dirs) {
        NSString *checkPrefs = [NSString stringWithFormat:@"/var/containers/Bundle/Application/%@/GeometryJump.app", dir];
        if ([fm fileExistsAtPath:checkPrefs isDirectory:nil]) {
            return [NSString stringWithFormat:@"/var/containers/Bundle/Application/%@/GeometryJump.app/GeometryJump", dir];
        }
    }
    
    return nil;
}
+ (NSString*)getGDBundlePath {
    // me when performance
    if (gdBundlePath != nil) return gdBundlePath;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError* err;
    NSArray *dirs = [fm contentsOfDirectoryAtPath:@"/var/containers/Bundle/Application" error:&err];
    if (err) {
        // assume we arent on jb or trollstore
        return nil;
    }
    // probably the most inefficient way of getting a bundle id, i need to figure out another way of doing this because this is just bad...
    for (NSString *dir in dirs) {
        NSString *checkPrefs = [NSString stringWithFormat:@"/var/containers/Bundle/Application/%@/GeometryJump.app", dir];
        if ([fm fileExistsAtPath:checkPrefs isDirectory:nil]) {
            gdBundlePath = [NSString stringWithFormat:@"/var/containers/Bundle/Application/%@/", dir];
            return gdBundlePath;
        }
    }
    return nil;
}

+ (void)showNotice:(UIViewController*)root title:(NSString *)title {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"common.notice".loc
        message:title
        preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"common.ok".loc style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [root presentViewController:alert animated:YES completion:nil];
}
+ (void)showError:(UIViewController*)root title:(NSString *)title error:(NSError *)error  {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"common.error".loc
        message:(error == nil) ? title : [NSString stringWithFormat:@"%@: %@", title, error.localizedDescription]
        preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"common.ok".loc style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [root presentViewController:alert animated:YES completion:nil];
}

+ (void)showErrorGlobal:(NSString *)title error:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"common.error".loc
        message:(error == nil) ? title : [NSString stringWithFormat:@"%@: %@", title, error.localizedDescription]
        preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"common.ok".loc style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];


    UIWindowScene *scene = (id)[UIApplication.sharedApplication.connectedScenes allObjects].firstObject;
    UIWindow *window = scene.windows.firstObject;
    if (window != nil) {
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

+ (NSString *)archName {
    const NXArchInfo *info = NXGetLocalArchInfo();
    NSString *typeOfCpu = [NSString stringWithUTF8String:info->description];
    return typeOfCpu;
}

+ (void)toggleKey:(NSString *)key {
    [[Utils getPrefs] setBool:![[Utils getPrefs] boolForKey:key] forKey:key];
}

// https://appideas.com/checksum-files-in-ios/
+ (NSString*)sha256sum:(NSString*)path {
    NSData *data = [NSData dataWithContentsOfFile:path];

    // getting the half only because the first few bytes are overwritten for some unknown reason, i blame ios!
    NSUInteger startData = data.length / 2;
    NSData *subdata = [data subdataWithRange:NSMakeRange(startData, data.length - startData)];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(subdata.bytes, (CC_LONG)subdata.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}
+ (NSString*)getGDBinaryHash {
    // TODO: change this to check for bundle version instead
    return [Utils sha256sum:[[LCPath bundlePath] URLByAppendingPathComponent:@"com.robtop.geometryjump.app/Info.plist"].path];
}

+ (BOOL)isSandboxed {
    // make sure we dont keep doing these read operations
    if (checkedSandboxed) return sandboxValue;
    checkedSandboxed = YES;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError* err;
    NSArray *dirs = [fm contentsOfDirectoryAtPath:@"/var" error:&err];
    if (err) {
        AppLog(@"[Geode] Sandboxed");
        sandboxValue = YES;
        return YES;
    }
    if (dirs.count == 0) {
        AppLog(@"[Geode] Sandboxed");
        sandboxValue = YES;
        return YES;
    }
    AppLog(@"[Geode] Not Sandboxed");
    sandboxValue = NO;
    return NO;
}

+ (NSUserDefaults*)getPrefs {
    if (![Utils isSandboxed]) {
        // fix for no sandbox because apparently it changes the pref location
        NSURL *libPath = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].lastObject;
        return [[NSUserDefaults alloc] initWithSuiteName:[libPath URLByAppendingPathComponent:@"Preferences/com.geode.launcher.plist"].path];
    } else {
        return [NSUserDefaults standardUserDefaults];
    }
}
+ (const char*)getKillAllPath {
    const char* paths[] = {
        "/usr/bin/killall",
        "/var/jb/usr/bin/killall",
        "/var/libexec/killall",
    };
    
    for (int i = 0; i < sizeof(paths)/sizeof(paths[0]); i++) {
        if (access(paths[i], X_OK) == 0) {
            return paths[i];
        }
    }
    return paths[0];
}

@end
