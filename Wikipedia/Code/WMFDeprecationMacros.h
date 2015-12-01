//
//  WMFDeprecationMacros.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#ifndef WMFDeprecationMacros_h
#define WMFDeprecationMacros_h

#ifndef WMF_DEPRECATE_BELOW_DEPLOY_TARGET
#define WMF_DEPRECATE_BELOW_DEPLOY_TARGET 0
#endif

#if WMF_DEPRECATE_BELOW_DEPLOY_TARGET && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_9_0
#define WMF_DEPRECATED_WHEN_DEPLOY_AT_LEAST_9 __deprecated_msg("This API was only necessary when deployment target was < 9. Please remove any code being executed when OS is less than 9.")
#else
#define WMF_DEPRECATED_WHEN_DEPLOY_AT_LEAST_9
#endif


#endif /* WMFDeprecationMacros_h */
