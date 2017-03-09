#import "MWKLanguageLinkResponseSerializer.h"
#import "MWKLanguageLink.h"
#import <WMF/WMF-Swift.h>

@implementation MWKLanguageLinkResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error {
    NSDictionary *json = [super responseObjectForResponse:response data:data error:error];
    if (!json) {
        return nil;
    }
    NSDictionary *pagesByID = json[@"query"][@"pages"];
    return [[pagesByID wmf_map:^id(id key, NSDictionary *result) {
        return [result[@"langlinks"] wmf_map:^MWKLanguageLink *(NSDictionary *jsonLink) {
            return [[MWKLanguageLink alloc] initWithLanguageCode:jsonLink[@"lang"]
                                                   pageTitleText:jsonLink[@"*"]
                                                            name:jsonLink[@"autonym"]
                                                   localizedName:jsonLink[@"langname"]];
        }];
    }] wmf_reject:^BOOL(id key, id obj) {
        return WMF_IS_EQUAL(obj, [NSNull null]);
    }];
}

@end
