#import "Utils.h"
#import <mach-o/arch.h>

@implementation Utils
+ (NSString*)gdBundleName {
    return @"com.robtop.geometryjump.app";
}
+ (BOOL)isJailbroken {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/var/jb"];
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

+ (void)showError:(UIViewController*)root title:(NSString *)title error:(NSError *)error  {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
        message:[NSString stringWithFormat:@"%@: %@", title, error.localizedDescription]
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

@end
