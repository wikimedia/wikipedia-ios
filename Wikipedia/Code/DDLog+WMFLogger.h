//
//  DDLog+WMFLogger.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/15/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFLogging.h"

@interface DDLog (WMFLogger)

+ (void)wmf_addLoggersForCurrentConfiguration;

+ (NSString*)wmf_currentLogFile;

@end
