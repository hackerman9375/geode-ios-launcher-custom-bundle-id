#import <Foundation/Foundation.h>
#import <mach-o/loader.h>

@interface Patcher : NSObject
@property(class, nonatomic, strong) NSMutableArray<NSNumber*>* patchedFuncs;

+ (BOOL)patchGDBinary:(NSURL*)from to:(NSURL*)to withHandlerAddress:(uint64_t)handlerAddress;
+ (bool)patchFunc:(NSMutableData*)data addr:(uint64_t)addr textSect:(struct section_64*)textSect withHandlerAddress:(uint64_t)handlerAddress;

@end
