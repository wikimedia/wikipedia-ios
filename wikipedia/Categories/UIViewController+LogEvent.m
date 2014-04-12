//  Created by Monte Hurd on 4/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+LogEvent.h"
#import "QueuesSingleton.h"

@implementation UIViewController (LogEvent)

-(void)logEvent:(NSDictionary *)event schema:(EventLogSchema)schema
{
    LogEventOp *logOp = [[LogEventOp alloc] initWithSchema:schema event:event];
    [[QueuesSingleton sharedInstance].eventLoggingQ addOperation:logOp];
}

@end
