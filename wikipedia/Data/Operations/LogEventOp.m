//  Created by Monte Hurd on 4/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LogEventOp.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "NSString+Extras.h"

#define LOG_ENDPOINT @"https://bits.wikimedia.org/event.gif"

//#define LOG_ENDPOINT @"http://localhost:8000/event.gif"

@implementation LogEventOp

-(NSDictionary *)getSchemaData
{
    return @{
        @(LOG_SCHEMA_CREATEACCOUNT): @{
            @"name": @"MobileWikiAppCreateAccount",
            @"revision": @8134803
        },
        @(LOG_SCHEMA_READINGSESSION): @{
            @"name": @"MobileWikiAppReadingSession",
            @"revision": @8134785
        },
        @(LOG_SCHEMA_EDIT): @{
            @"name": @"MobileWikiAppEdit",
            @"revision": @8134783
        },
        @(LOG_SCHEMA_LOGIN): @{
            @"name": @"MobileWikiAppLogin",
            @"revision": @8134781
        }
    };
}

- (id)initWithSchema: (EventLogSchema)schema
               event: (NSDictionary *)event
{
    self = [super init];
    if (self) {

        NSDictionary *schemaData = [self getSchemaData];

        NSDictionary *payload =
        @{
          @"event"    : event,
          @"revision" : schemaData[@(schema)][@"revision"],
          @"schema"   : schemaData[@(schema)][@"name"]
          };

        NSData *payloadJsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
        NSString *payloadJsonString = [[NSString alloc] initWithData:payloadJsonData encoding:NSUTF8StringEncoding];
        NSString *encodedPayloadJsonString = [payloadJsonString urlEncodedUTF8String];
        NSString *urlString = [NSString stringWithFormat:@"%@?%@;", LOG_ENDPOINT, encodedPayloadJsonString];
        
        self.request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
        
        self.completionBlock = ^(){
            //NSLog(@"EVENT LOGGING COMPLETED");
        };
    }
    return self;
}

@end
