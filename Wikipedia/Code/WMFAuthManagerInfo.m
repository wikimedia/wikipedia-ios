
#import "WMFAuthManagerInfo.h"

@implementation WMFAuthManagerInfo

+ (NSValueTransformer*)captchaIDJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSArray* requests, BOOL* success, NSError* __autoreleasing* error) {
        NSString* captchaID = [requests bk_reduce:nil withBlock:^id (id sum, NSDictionary* obj) {
            if ([obj[@"id"] isEqualToString:@"CaptchaAuthenticationRequest"]) {
                return obj[@"fields"][@"captchaId"][@"value"];
            } else {
                return sum;
            }
        }];
        return captchaID;
    }];
}

+ (NSValueTransformer*)captchaURLFragmentJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSArray* requests, BOOL* success, NSError* __autoreleasing* error) {
        NSString* captchaID = [requests bk_reduce:nil withBlock:^id (id sum, NSDictionary* obj) {
            if ([obj[@"id"] isEqualToString:@"CaptchaAuthenticationRequest"]) {
                return obj[@"fields"][@"captchaInfo"][@"value"];
            } else {
                return sum;
            }
        }];
        return captchaID;
    }];
}

+ (NSValueTransformer*)canCreateAccountJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSString* value, BOOL* success, NSError* __autoreleasing* error) {
        if (value) {
            return @YES;
        } else {
            return @NO;
        }
    }];
}

+ (NSValueTransformer*)canAuthenticateJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSString* value, BOOL* success, NSError* __autoreleasing* error) {
        if (value) {
            return @YES;
        } else {
            return @NO;
        }
    }];
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{
               WMF_SAFE_KEYPATH(WMFAuthManagerInfo.new, captchaID): @"authmanagerinfo.requests",
               WMF_SAFE_KEYPATH(WMFAuthManagerInfo.new, captchaURLFragment): @"authmanagerinfo.requests",
               WMF_SAFE_KEYPATH(WMFAuthManagerInfo.new, canAuthenticate): @"authmanagerinfo.canauthenticatenow",
               WMF_SAFE_KEYPATH(WMFAuthManagerInfo.new, canCreateAccount): @"authmanagerinfo.cancreateaccounts",
    };
}

@end
