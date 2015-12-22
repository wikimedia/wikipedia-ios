
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
#import "WMFDeprecationMacros.h"
#import "NSProcessInfo+WMFOperatingSystemVersionChecks.h"
#import "NSArray+WMFMapping.h"
#import "NSMutableArray+WMFSafeAdd.h"

#define URL_PRIVACY_POLICY @"https://m.wikimediafoundation.org/wiki/Privacy_Policy"

#endif
