#import <WMF/WMFApiJsonResponseSerializer.h>
#import <WMF/WMFNetworkUtilities.h>
#import <WMF/WMFLogging.h>

@implementation WMFApiJsonResponseSerializer

- (instancetype)init {
    self = [super init];
    if (self) {
        NSMutableIndexSet *set = [self.acceptableStatusCodes mutableCopy];
        [set addIndex:304];
        self.acceptableStatusCodes = set;
    }
    return self;
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error {
    NSDictionary *json = [super responseObjectForResponse:response data:data error:error];
    if (!json || (error != NULL && *error != nil)) {
        return nil;
    }
    NSDictionary *apiError = json[@"error"];
    if (apiError) {
        if (error) {
            *error = WMFErrorForApiErrorObject(apiError);
        }
        return nil;
    }

#if DEBUG
    NSDictionary *warnings = json[@"warnings"];
    if (warnings) {
        DDLogWarn(@"\n\n\nWarnings for request:\n%@\n%@", response.URL.absoluteString, warnings);
    }
#endif

    return json;
}

@end
