#import <Foundation/Foundation.h>

@interface NSString (Localization)
@property(readonly, nonnull, getter=localized) NSString* loc;
- (instancetype _Nonnull)localized;
- (instancetype _Nonnull)localizeWithFormat:(NSString* _Nonnull)format, ...;
@end
