#import <Foundation/Foundation.h>

@interface NSURLComponents (WMFURLParsing)

@property (nonatomic, copy, readonly, nullable) NSString* wmf_domain;

@property (nonatomic, copy, readonly, nullable) NSString* wmf_language;

@property (nonatomic, copy, readonly, nullable) NSString* wmf_title;

@end
