//  Created by Monte Hurd on 5/8/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWNetworkOp.h"

#import "BundledJsonEnum.h"

@interface ConfigFileSyncOp : MWNetworkOp

// Syncs any bundled app json file with a remote file.

// Only does so if age of app file exceeds maxAge or if the file isn't found in app.

// Nice because we can sync any bundled files with any periodicity
// required just by firing these operations off occasionally.

// They self-cancel if maxAge has not been exceeded, so fire away.

- (id)initForBundledJsonFile: (BundledJsonFile)file
                      maxAge: (CGFloat)maxAge;

@end
