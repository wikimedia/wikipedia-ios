//  Created by Monte Hurd on 5/8/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWNetworkOp.h"

#import "AssetsFileEnum.h"

@interface SyncAssetsFileOp : MWNetworkOp

// Syncs /AppData/Documents/assets/ file with a remote file.

// Only does so if age of app file exceeds maxAge or if the file isn't found in app.

// Nice because we can sync assets files with any periodicity
// required just by firing these operations off occasionally.

// They self-cancel if maxAge has not been exceeded, so fire away.

- (id)initForAssetsFile: (AssetsFileEnum)file
                 maxAge: (CGFloat)maxAge;

@end
