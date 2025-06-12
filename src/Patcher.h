#import <Foundation/Foundation.h>
#import <mach-o/loader.h>

@interface Patcher : NSObject
@property(class, nonatomic, strong) NSMutableArray<NSNumber*>* patchedFuncs;
@property(class, nonatomic, strong) NSMutableDictionary<NSString*, NSData*>* originalBytes;

+ (BOOL)patchGDBinary:(NSURL*)from to:(NSURL*)to withHandlerAddress:(uint64_t)handlerAddress;

@end
