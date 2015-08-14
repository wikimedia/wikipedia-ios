//
//  PiwikDebugDispatcher.h
//  PiwikTracker
//
//  Created by Mattias Levin on 29/08/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PiwikDispatcher.h"


/**
 A dispatcher that will only print events to the console and never send anything to the Piwik server.
 */
@interface PiwikDebugDispatcher : NSObject <PiwikDispatcher>

@property (nonatomic, strong) id<PiwikDispatcher> wrappedDispatcher;

@end
