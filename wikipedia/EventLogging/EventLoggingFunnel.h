//
//  EventLoggingFunnel.h
//  Wikipedia
//
//  Created by Brion on 5/28/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Base class for EventLogging multi-stage funnels.
 *
 * Instantiate one of the subclasses at the beginning of the
 * activity to be logged, and if necessary pass the funnel object
 * down into further stages of your pipeline (eg from one View
 * Controller to the next), then call the log* methods.
 *
 * Derived classes will contain specific log* methods for each
 * potential logging action variant for readability in calling
 * code.
 */
@interface EventLoggingFunnel : NSObject

@property NSString *schema;
@property int revision;

/**
 * This constructor should be called internally by derived classes
 * to encapsulate the schema name and version.
 */
-(id)initWithSchema:(NSString *)schema version:(int)revision;

/**
 * An optional preprocessing step before recording data passed
 * to the 'log:' method(s).
 *
 * This can be convenient when many steps of a funnel require
 * a common set of parameters, so they don't have to be repeated.
 *
 * Leave un-overridden if no preprocessing is needed.
 */
-(NSDictionary *)preprocessData:(NSDictionary *)eventData;

/**
 * The basic log: method takes a bare dictionary, which will
 * get run through preprocessData: and then sent off to the
 * background logging operation queue.
 *
 * For convenience, derivded classes should contain specific
 * log* methods for each potential logging action variant for
 * readibility in calling code (and type safety on params!)
 */
-(void)log:(NSDictionary *)eventData;


/**
 * Helper function to generate a per-use UUID
 */
-(NSString *)singleUseUUID;

/**
 * Helper function to generate a persistent per-app-install UUID
 */
-(NSString *)persistentUUID:(NSString *)key;

@end
