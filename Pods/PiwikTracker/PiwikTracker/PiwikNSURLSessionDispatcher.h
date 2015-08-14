//
//  PiwikNSURLSessionDispatcher.h
//  PiwikTracker
//
//  Created by Mattias Levin on 29/08/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PiwikDispatcher.h"


/**
 A dispatcher that will use NSURLSession to send requests to the Piwik server.
 */
@interface PiwikNSURLSessionDispatcher : NSObject <PiwikDispatcher>

@property (nonatomic, strong) NSString *userAgent;

- (instancetype)initWithPiwikURL:(NSURL*)piwikURL;

@end
