//  Created by Monte Hurd on 4/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWNetworkOp.h"

@interface LogEventOp : MWNetworkOp

/**
 * Most code should not call this directly -- use an EventLoggingFunnel subclass.
 */
- (id)initWithSchema: (NSString *)schema
            revision: (int)revision
               event: (NSDictionary *)event
                wiki: (NSString *)wiki;

@end
