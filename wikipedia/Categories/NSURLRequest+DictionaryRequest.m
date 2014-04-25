//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSURLRequest+DictionaryRequest.h"
#import "NSString+Extras.h"
#import "WikipediaAppUtils.h"

@implementation NSURLRequest (DictionaryRequest)

+(NSString *) constructEncodedURL:(NSDictionary *)parameters
{
    NSMutableString *body = [NSMutableString string];
    
    for (NSString *key in parameters) {
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
    [request addValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
    [request addValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
    // NSLog(@"%@", [WikipediaAppUtils versionedUserAgent]);
    [request setHTTPBody:[[NSURLRequest constructEncodedURL:parameters] dataUsingEncoding:NSUTF8StringEncoding]];
    return request;
}

+ (NSURLRequest *)getRequestWithURL:(NSURL *)url
                          parameters:(NSDictionary *)parameters {
    
    NSString *body = [NSURLRequest constructEncodedURL:parameters];
    body = [[url.absoluteString stringByAppendingString:@"?"] stringByAppendingString:body];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:body]];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
    [request addValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
    // NSLog(@"%@", [WikipediaAppUtils versionedUserAgent]);
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    return request;
}
@end
