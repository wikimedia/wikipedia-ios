//  Created by Monte Hurd on 4/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWNetworkOp.h"

typedef enum {

    //https://meta.wikimedia.org/wiki/Schema:MobileWikiAppCreateAccount
    LOG_SCHEMA_CREATEACCOUNT = 0,

    //https://meta.wikimedia.org/wiki/Schema:MobileWikiAppReadingSession
    LOG_SCHEMA_READINGSESSION = 1,

    //https://meta.wikimedia.org/wiki/Schema:MobileWikiAppEdit
    LOG_SCHEMA_EDIT = 2,
    
    //https://meta.wikimedia.org/wiki/Schema:MobileWikiAppLogin
    LOG_SCHEMA_LOGIN = 3
    
} EventLogSchema;

@interface LogEventOp : MWNetworkOp

- (id)initWithSchema: (EventLogSchema)schema
               event: (NSDictionary *)event;

@end
