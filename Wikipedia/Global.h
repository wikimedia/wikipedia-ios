
#ifndef Wikipedia_Global_h
#define Wikipedia_Global_h

#import "WMFLogging.h"
#import "WMFDirectoryPaths.h"
#import "WMFGCDHelpers.h"
#import "WMFLocalization.h"
#import "WMFMath.h"
#import "NSError+WMFExtensions.h"
#import "NSObjectUtilities.h"
#import "WMFOutParamUtils.h"
#import "UIColor+WMFStyle.h"

#import <libextobjc/EXTScope.h>
#import <KVOController/FBKVOController.h>
#import <BlocksKit/BlocksKit.h>

// Need to import it this way since umbrella header doesn't have AnyPromise declarations
#import <PromiseKit/PromiseKit.h>

#import "WMFBlockDefinitions.h"
#import "WMFComparison.h"

//TODO: when refactoring networking, this should be scoped to those classes
#define LEAD_IMAGE_WIDTH (([UIScreen mainScreen].scale > 1) ? 640 : 320)

#ifndef PIWIK_ENABLED
    #if NDEBUG
        #define PIWIK_ENABLED 0
    #else
        #define PIWIK_ENABLED 1
    #endif
#endif

#endif
