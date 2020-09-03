#import <Foundation/Foundation.h>

@interface NSCharacterSet (WMFLinkParsing)

+ (NSCharacterSet *)wmf_URLArticleTitlePathComponentAllowedCharacterSet;
+ (NSCharacterSet *)wmf_relativePathAndFragmentAllowedCharacterSet;

@end
