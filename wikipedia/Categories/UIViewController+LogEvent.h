//  Created by Monte Hurd on 4/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "LogEventOp.h"

@interface UIViewController (LogEvent)

-(void)logEvent: (NSDictionary *)event
         schema: (EventLogSchema)schema;

@end
