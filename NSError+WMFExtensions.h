
#import <Foundation/Foundation.h>

extern NSString* const WMFErrorDomain;

typedef NS_ENUM(NSInteger, WMFErrorType) {
    
    WMFErrorTypeStringLength,
    WMFErrorTypeStringMissingParameter,
};

@interface NSError (WMFExtensions)

+ (NSError*)wmf_errorWithType:(WMFErrorType)type userInfo:(NSDictionary*)userInfo;

@end
