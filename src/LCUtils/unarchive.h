#import <Foundation/Foundation.h>

extern int extract(NSString* fileToExtract, NSString* extractionPath, NSProgress* progress);
extern int compress(NSString* fileToCompress, NSString* zipPath, NSProgress* progress);
extern CGFloat getProgress();
extern CGFloat getProgressCompress();
