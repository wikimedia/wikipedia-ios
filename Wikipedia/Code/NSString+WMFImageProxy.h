#import <Foundation/Foundation.h>

@interface NSString (WMFImageProxy)

- (NSString*)wmf_stringWithLocalhostProxyPrefix;
- (NSString*)wmf_srcsetValueWithLocalhostProxyPrefixes;

@end
