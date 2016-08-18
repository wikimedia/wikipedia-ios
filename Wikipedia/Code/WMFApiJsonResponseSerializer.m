#import "WMFApiJsonResponseSerializer.h"
#import "WMFNetworkUtilities.h"

@implementation WMFApiJsonResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error {
    NSDictionary *json = [super responseObjectForResponse:response data:data error:error];
    if (!json) {
        return nil;
    }
    NSDictionary *apiError = json[@"error"];
    if (apiError) {
        if (error) {
            *error = WMFErrorForApiErrorObject(apiError);
        }
        return nil;
    }
    return json;
}

@end
