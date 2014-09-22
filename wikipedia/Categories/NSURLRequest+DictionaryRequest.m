//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSURLRequest+DictionaryRequest.h"
#import "NSString+Extras.h"
#import "SessionSingleton.h"
#import "WikipediaAppUtils.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>

@implementation NSURLRequest (DictionaryRequest)

+(NSString *) constructEncodedURL:(NSDictionary *)parameters
{
    NSMutableString *body = [NSMutableString string];
    
    for (NSString *key in parameters.copy) {
        NSString *val = [parameters objectForKey:key];
        if ([body length])
            [body appendString:@"&"];
        [body appendFormat:@"%@=%@", [[key description] urlEncodedUTF8String],
         [[val description] urlEncodedUTF8String]];
    }
    return body;
}

+ (NSURLRequest *)postRequestWithURL:(NSURL *)url
                          parameters:(NSDictionary *)parameters {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request addValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
    // NSLog(@"%@", [WikipediaAppUtils versionedUserAgent]);
    [self addMCCMNCToRequestIfAppropriate:request];
    [request setHTTPBody:[[NSURLRequest constructEncodedURL:parameters] dataUsingEncoding:NSUTF8StringEncoding]];
    return request;
}

+ (NSURLRequest *)getRequestWithURL:(NSURL *)url
                          parameters:(NSDictionary *)parameters {
    
    NSString *body = [NSURLRequest constructEncodedURL:parameters];
    body = [[url.absoluteString stringByAppendingString:@"?"] stringByAppendingString:body];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:body]];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request addValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
    // NSLog(@"%@", [WikipediaAppUtils versionedUserAgent]);
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [self addMCCMNCToRequestIfAppropriate:request];
    return request;
}

#pragma MCC-MNC Logging

// Add the MCC-MNC code asn HTTP (protocol) header once per session when user using cellular data connection.
// Logging will be done in its own file with specific fields. See the following URL for details.
// http://lists.wikimedia.org/pipermail/wikimedia-l/2014-April/071131.html

+(void) addMCCMNCToRequestIfAppropriate: (NSMutableURLRequest*) req
{
    /* MCC-MNC logging is only turned with an API hook */
    if (![SessionSingleton sharedInstance].sendUsageReports ||
        [SessionSingleton sharedInstance].zeroConfigState.sentMCCMNC ||
        [req.URL.host rangeOfString:@".m.wikipedia.org"].location == NSNotFound ||
        [req.URL.relativePath rangeOfString:@"/w/api.php"].location == NSNotFound) {
        return;
    } else {
        CTCarrier *mno = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];
        if (mno) {
            SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(NULL,
                                                                                           [[[req URL] host] UTF8String]);
            SCNetworkReachabilityFlags reachabilityFlags;
            SCNetworkReachabilityGetFlags(reachabilityRef, &reachabilityFlags);
            
            // The following is a good functioning mask in practice for the case where
            // cellular is being used, with wifi not on / there are no known wifi APs.
            // When wifi is on with a known wifi AP connection, kSCNetworkReachabilityFlagsReachable
            // is present, but kSCNetworkReachabilityFlagsIsWWAN is not present.
            if (reachabilityFlags == (kSCNetworkReachabilityFlagsIsWWAN
                                      | kSCNetworkReachabilityFlagsReachable
                                      | kSCNetworkReachabilityFlagsTransientConnection)) {
                // In iOS disentangling network MCC-MNC from SIM MCC-MNC not in API yet.
                // So let's use the same value for both parts of the field.
                NSString *mcc = mno.mobileCountryCode ? mno.mobileCountryCode : @"000";
                NSString *mnc = mno.mobileNetworkCode ? mno.mobileNetworkCode : @"000";
                NSString *mccMnc = [[NSString alloc] initWithFormat:@"%@-%@,%@-%@", mcc, mnc, mcc, mnc];
                [SessionSingleton sharedInstance].zeroConfigState.sentMCCMNC = true;
                [req addValue:mccMnc forHTTPHeaderField:@"X-MCCMNC"];
                // NSLog(@"%@", mccMnc);
            }
        }
    }
}


@end
