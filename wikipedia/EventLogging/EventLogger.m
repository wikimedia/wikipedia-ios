//  Created by Monte Hurd on 4/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "EventLogger.h"
#import "NSString+Extras.h"
#import "WikipediaAppUtils.h"

#define LOG_ENDPOINT @"https://bits.wikimedia.org/event.gif"
//#define LOG_ENDPOINT @"http://localhost:8000/event.gif"

@implementation EventLogger

- (instancetype)initAndLogEvent: (NSDictionary *)event
                      forSchema: (NSString *)schema
                       revision: (int)revision
                           wiki: (NSString *)wiki
{
    self = [super init];
    if (self) {
        
        if (event && schema && wiki){
            NSDictionary *payload =
            @{
              @"event"    : event,
              @"revision" : @(revision),
              @"schema"   : schema,
              @"wiki"     : wiki
              };
            
            NSData *payloadJsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
            NSString *payloadJsonString = [[NSString alloc] initWithData:payloadJsonData encoding:NSUTF8StringEncoding];
            //NSLog(@"%@", payloadJsonString);
            NSString *encodedPayloadJsonString = [payloadJsonString urlEncodedUTF8String];
            NSString *urlString = [NSString stringWithFormat:@"%@?%@;", LOG_ENDPOINT, encodedPayloadJsonString];
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
            [request addValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
            
            (void)[[NSURLConnection alloc] initWithRequest:request delegate:nil];
        }
    }
    return self;
}

@end
