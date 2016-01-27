//
//  WMFTestEnvironment.h
//  Wikipedia
//
//  Created by Brian Gerstle on 1/22/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#ifndef WMFTestEnvironment_h
#define WMFTestEnvironment_h

#import <Foundation/Foundation.h>
#import <stdlib.h>

static inline BOOL WMFIsTravis() {
    const char* travisValue = getenv("TRAVIS");
    return travisValue != NULL;
}

#endif /* WMFTestEnvironment_h */
