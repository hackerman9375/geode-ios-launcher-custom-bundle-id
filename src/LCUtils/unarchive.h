#import <Foundation/Foundation.h>

extern int extract(NSString* fileToExtract, NSString* extractionPath, NSProgress* progress);
extern int compress(NSString* fileToCompress, NSString* zipPath, NSProgress* progress);
extern int compressEnt(NSString* docPath, NSString* zipPath, BOOL* force);
extern CGFloat getProgress();
extern CGFloat getProgressCompress();
