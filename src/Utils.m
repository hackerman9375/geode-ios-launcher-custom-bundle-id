#import "Utils.h"
#import "LCUtils/Shared.h"
#import <CommonCrypto/CommonCrypto.h>
#import <mach-o/arch.h>

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

+ (NSString*)getGeodeVersion {
    NSString *verTag = [[NSUserDefaults standardUserDefaults] stringForKey:@"CURRENT_VERSION_TAG"];
    return (verTag) ? verTag : @"Geode not installed";
}

+ (NSString*)getGeodeDebURL {
    return @"";
}

+ (void)updateGeodeVersion:(NSString *)newVer {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:newVer forKey:@"CURRENT_VERSION_TAG"];
    [userDefaults synchronize]; // apple says this is not recommended... DOES ANYWAYS
}

+ (NSString*)getGeodeReleaseURL {
    //return @"http://192.168.200.1:38000";
    return @"https://api.github.com/repos/geode-sdk/geode/releases/latest";
}

// ai generated because i cant figure this out
+ (UIImageView *)imageViewFromPDF:(NSString *)pdfName {
    NSURL *pdfURL = [[NSBundle mainBundle] URLForResource:pdfName withExtension:@"pdf"];
    if (!pdfURL) {
        NSLog(@"PDF file not found in bundle: %@", pdfName);
        return nil;
    }

    CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithURL((__bridge CFURLRef)pdfURL);
    if (!pdfDocument) {
        NSLog(@"Failed to create PDF document from URL: %@", pdfURL);
        return nil;
    }

    CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfDocument, 1); // Get the first page
    if (!pdfPage) {
        NSLog(@"Failed to get the first page of the PDF document.");
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
        NSLog(@"Error reading directory: %@", error.localizedDescription);
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
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError* err;
    NSArray *dirs = [fm contentsOfDirectoryAtPath:@"/var/mobile/Containers/Data/Application" error:&err];
    if (err) {
        // assume we arent on jb or trollstore
        return nil;
    }
    // probably the most inefficient way of getting a bundle id, i need to figure out another way of doing this because this is just bad...
    for (NSString *dir in dirs) {
        NSString *checkPrefs = [NSString stringWithFormat:@"/var/mobile/Containers/Data/Application/%@/Library/HTTPStorages/com.robtop.geometryjump", dir];
        if ([fm fileExistsAtPath:checkPrefs isDirectory:nil]) {
            return [NSString stringWithFormat:@"/var/mobile/Containers/Data/Application/%@", dir];
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

+ (void)showNotice:(UIViewController*)root title:(NSString *)title {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notice"
        message:title
        preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [root presentViewController:alert animated:YES completion:nil];
}
+ (void)showError:(UIViewController*)root title:(NSString *)title error:(NSError *)error  {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
        message:(error == nil) ? title : [NSString stringWithFormat:@"%@: %@", title, error.localizedDescription]
        preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [root presentViewController:alert animated:YES completion:nil];
}

+ (NSString *)archName {
    const NXArchInfo *info = NXGetLocalArchInfo();
    NSString *typeOfCpu = [NSString stringWithUTF8String:info->description];
    return typeOfCpu;
}

+ (void)toggleKey:(NSString *)key {
    NSLog(@"godelol %@", key);
    [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:key] forKey:key];
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
    return [Utils sha256sum:[[LCPath bundlePath] URLByAppendingPathComponent:@"com.robtop.geometryjump.app/GeometryJump"].path];
}

@end
