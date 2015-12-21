
#import "WMFArticleRequestSerializer.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "WMFNetworkUtilities.h"
#import "MWKTitle.h"
#import "UIScreen+WMFImageWidth.h"

@implementation WMFArticleRequestSerializer


- (NSURLRequest*)requestBySerializingRequest:(NSURLRequest*)request
                              withParameters:(id)parameters
                                       error:(NSError* __autoreleasing*)error {
    [self updateMCCMNCHeaderForURL:[request URL]];
    NSMutableDictionary* serializedParams = [self paramsForTitle:(MWKTitle*)parameters];

    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSMutableDictionary*)paramsForTitle:(MWKTitle*)title {
    NSMutableDictionary* params = @{
        @"format": @"json",
        @"action": @"mobileview",
        @"sectionprop": WMFJoinedPropertyParameters(@[@"toclevel", @"line", @"anchor", @"level", @"number",
                                                      @"fromtitle", @"index"]),
        @"noheadings": @"true",
        @"sections": @"all",
        @"page": title.text,
        @"thumbwidth": [[UIScreen mainScreen] wmf_leadImageWidthForScale],
        @"prop": WMFJoinedPropertyParameters(@[@"sections", @"text", @"lastmodified", @"lastmodifiedby",
                                               @"languagecount", @"id", @"protection", @"editable", @"displaytitle",
                                               @"thumb", @"description", @"image", @"revision"])
    }.mutableCopy;

    return params;
}

#pragma mark - MCCMNC Header

// Only send this once per session (what's a session?? In this case "a launch"). Should probabaly revisit.
// Add the MCC-MNC code asn HTTP (protocol) header once per session when user using cellular data connection.
// Logging will be done in its own file with specific fields. See the following URL for details.
// http://lists.wikimedia.org/pipermail/wikimedia-l/2014-April/071131.html

static BOOL _headerSent = NO;
+ (BOOL)didSendMCCMNCheader {
    return _headerSent;
}

+ (void)setDidSendMCCMNCHeader {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _headerSent = YES;
    });
}

/*
 * Should this really be based on the URL?
 * The serializer "wants" to be agnostic to the actual URL.
 * Can we check against a base URL at least?
 */
- (void)updateMCCMNCHeaderForURL:(NSURL*)url {
    if (self.shouldSendMCCMNCheader && ![[self class] didSendMCCMNCheader] && [self hasCellularProvider] && [self urlIsReachableOverCellularNetwork:url]) {
        [self addMCCMNCHeader];
    } else {
        [self removeMCCMNCHeader];
    }
}

- (void)addMCCMNCHeader {
    CTCarrier* mno = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];
    // In iOS disentangling network MCC-MNC from SIM MCC-MNC not in API yet.
    // So let's use the same value for both parts of the field.
    NSString* mcc    = mno.mobileCountryCode ? mno.mobileCountryCode : @"000";
    NSString* mnc    = mno.mobileNetworkCode ? mno.mobileNetworkCode : @"000";
    NSString* mccMnc = [[NSString alloc] initWithFormat:@"%@-%@,%@-%@", mcc, mnc, mcc, mnc];
    [self setValue:mccMnc forHTTPHeaderField:@"X-MCCMNC"];
    [[self class] setDidSendMCCMNCHeader];
}

- (void)removeMCCMNCHeader {
    [self setValue:nil forHTTPHeaderField:@"X-MCCMNC"];
}

#pragma mark - MCCMNC Cellular Checks

- (BOOL)hasCellularProvider {
    CTCarrier* mno = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];
    if (mno) {
        return YES;
    }
    return NO;
}

- (BOOL)urlIsReachableOverCellularNetwork:(NSURL*)url {
    SCNetworkReachabilityRef reachabilityRef =
        SCNetworkReachabilityCreateWithName(NULL, [[url host] UTF8String]);
    SCNetworkReachabilityFlags reachabilityFlags;
    SCNetworkReachabilityGetFlags(reachabilityRef, &reachabilityFlags);

    // The following is a good functioning mask in practice for the case where
    // cellular is being used, with wifi not on / there are no known wifi APs.
    // When wifi is on with a known wifi AP connection, kSCNetworkReachabilityFlagsReachable
    // is present, but kSCNetworkReachabilityFlagsIsWWAN is not present.
    if (reachabilityFlags == (
            kSCNetworkReachabilityFlagsIsWWAN
            |
            kSCNetworkReachabilityFlagsReachable
            |
            kSCNetworkReachabilityFlagsTransientConnection
            )
        ) {
        return YES;
    }

    return NO;
}

@end
