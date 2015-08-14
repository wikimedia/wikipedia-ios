//
//  PiwikDebugDispatcher.m
//  PiwikTracker
//
//  Created by Mattias Levin on 29/08/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import "PiwikDebugDispatcher.h"


@implementation PiwikDebugDispatcher

- (void)setUserAgent:(NSString *)userAgent {
    NSLog(@"Set custom user agent: \n%@", userAgent);
}

- (void)sendSingleEventWithParameters:(NSDictionary*)parameters
                              success:(void (^)())successBlock
                              failure:(void (^)(BOOL shouldContinue))failureBlock {
  
  //NSLog(@"Dispatch single event with debug dispatcher");
  
  NSLog(@"Request: \n%@", parameters);
  
  successBlock();
  
}


- (void)sendBulkEventWithParameters:(NSDictionary*)parameters
                            success:(void (^)())successBlock
                            failure:(void (^)(BOOL shouldContinue))failureBlock {
  
  //NSLog(@"Dispatch batch events with debug dispatcher");
  
  NSLog(@"Request: \n%@", parameters);
  
  successBlock();
  
}


@end
