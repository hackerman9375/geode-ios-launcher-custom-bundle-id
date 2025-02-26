#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LCContainer : NSObject <NSCopying>
    @property (nonatomic, copy) NSString *folderName;
    @property (nonatomic, copy) NSString *name;
    @property (nonatomic, copy) NSString *isShared;
@end
