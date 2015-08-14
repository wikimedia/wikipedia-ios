//
//  PiwikNSURLSessionDispatcher.m
//  PiwikTracker
//
//  Created by Mattias Levin on 29/08/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import "PiwikNSURLSessionDispatcher.h"


@interface PiwikNSURLSessionDispatcher ()

@property (nonatomic, strong) NSURL *piwikURL;

@end


static NSUInteger const PiwikHTTPRequestTimeout = 5;


@implementation PiwikNSURLSessionDispatcher


- (instancetype)initWithPiwikURL:(NSURL*)piwikURL {
  self = [super init];
  if (self) {
    _piwikURL = piwikURL;
  }
  return self;
}

- (void)sendSingleEventWithParameters:(NSDictionary*)parameters
                              success:(void (^)())successBlock
                              failure:(void (^)(BOOL shouldContinue))failureBlock {
  
  //NSLog(@"Dispatch single event with NSURLSession dispatcher");
    
  NSMutableArray *parameterPairs = [NSMutableArray arrayWithCapacity:parameters.count];
  [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [parameterPairs addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
  }];
  
  // URL encoded query string
  NSString *queryString = [[parameterPairs componentsJoinedByString:@"&"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  
  NSURL *URL = [NSURL URLWithString:[@"?" stringByAppendingString:queryString] relativeToURL:self.piwikURL];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                  initWithURL:URL
                                  cachePolicy:NSURLRequestReloadIgnoringCacheData
                                  timeoutInterval:PiwikHTTPRequestTimeout];
  if (self.userAgent) {
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
  }
    
  request.HTTPMethod = @"GET";
  
  [self sendRequest:request success:successBlock failure:failureBlock];
  
}


- (void)sendBulkEventWithParameters:(NSDictionary*)parameters
                            success:(void (^)())successBlock
                            failure:(void (^)(BOOL shouldContinue))failureBlock {
  
  //NSLog(@"Dispatch batch events with NSURLSession dispatcher");
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.piwikURL
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                          timeoutInterval:PiwikHTTPRequestTimeout];
  if (self.userAgent) {
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
  }
    
  request.HTTPMethod = @"POST";
  
  NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
  [request setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
  
  NSError *error;
  request.HTTPBody = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
  
  [self sendRequest:request success:successBlock failure:failureBlock];
  
}


- (void)sendRequest:(NSURLRequest*)request success:(void (^)())successBlock failure:(void (^)(BOOL shouldContinue))failureBlock {
  
  NSURLSession *session = [NSURLSession sharedSession];
  
  NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (!error) {
      successBlock();
    } else {
      failureBlock([self shouldAbortdispatchForNetworkError:error]);
    }
  }];
  
  [task resume];
  
}


// Should the dispatch be aborted and pending events rescheduled
- (BOOL)shouldAbortdispatchForNetworkError:(NSError*)error {
  
  if (error.code == NSURLErrorBadURL ||
      error.code == NSURLErrorUnsupportedURL ||
      error.code == NSURLErrorCannotFindHost ||
      error.code == NSURLErrorCannotConnectToHost ||
      error.code == NSURLErrorDNSLookupFailed) {
    return YES;
  } else {
    return NO;
  }
  
}


@end
