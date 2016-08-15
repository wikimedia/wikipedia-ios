//
//  NSUserDefaults+WMFReset.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (WMFReset)

/**
 *  Resets the receiver to its default values.
 *
 *  Removes all values in the persistent application domain (based on the main
 * bundle). Once performed, the values will
 *  equal the defaults registered in the application domain.
 *
 *  @note <code>+[NSUserDefaults resetStandardDefaults]</code> (despite the
 * name) is not the same as this method.
 *
 *  @see -[NSUserDefaults registerDefaults]
 */
- (void)wmf_resetToDefaultValues;

@end
