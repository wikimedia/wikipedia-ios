//
//  NSTimeZone+WMFTestingUtils.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/12/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@import Quick;

#define resetTimeZoneAfterEach() afterEach(^{ \
  [NSTimeZone wmf_resetDefaultTimeZone];      \
})

@interface NSTimeZone (WMFTestingUtils)

+ (void)wmf_setDefaultTimeZoneForName:(NSString *)name;

/**
 *  Resets the @c defaultTimeZone to its default value, the current @c systemTimeZone.
 */
+ (void)wmf_resetDefaultTimeZone;

+ (void)wmf_forEachKnownTimeZoneAsDefault:(dispatch_block_t)block;

@end
