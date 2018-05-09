#import <WMF/EventLogger.h>
#import <WMF/NSString+WMFExtras.h>
#import <WMF/WikipediaAppUtils.h>
#import <WMF/WMF-Swift.h>

NSString *const WMFLoggingEndpoint =
    // production
    @"https://meta.wikimedia.org/beacon/event";
// testing
// @"http://deployment.wikimedia.beta.wmflabs.org/beacon/event";

@implementation EventLogger

- (instancetype)initAndLogEvent:(NSDictionary *)event
                      forSchema:(NSString *)schema
                       revision:(int)revision
                           wiki:(NSString *)wiki {
    self = [super init];
    if (self) {
        if (event && schema && wiki) {

#if WMF_IS_NEW_EVENT_LOGGING_ENABLED
            NSDictionary *capsule = [NSDictionary wmf_eventCapsuleWithEvent:event schema:schema revision:revision wiki:wiki];
            [[WMFEventLoggingService sharedInstance] logEvent:capsule];
#else
            NSDictionary *payload =
                @{
                    @"event": event,
                    @"revision": @(revision),
                    @"schema": schema,
                    @"wiki": wiki
                };
            NSData *payloadJsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
            NSString *payloadJsonString = [[NSString alloc] initWithData:payloadJsonData encoding:NSUTF8StringEncoding];
            //NSLog(@"%@", payloadJsonString);
            NSString *encodedPayloadJsonString = [payloadJsonString wmf_UTF8StringWithPercentEscapes];
            NSString *urlString = [NSString stringWithFormat:@"%@?%@;", WMFLoggingEndpoint, encodedPayloadJsonString];
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
            [request setValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
            [[[NSURLSession sharedSession] dataTaskWithRequest:request] resume];
#endif
        }
    }
    return self;
}

@end
