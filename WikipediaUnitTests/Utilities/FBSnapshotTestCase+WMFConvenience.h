//
//  FBSnapshotTestCase+WMFConvenience.h
//  Wikipedia
//
//  Created by Monte Hurd on 8/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "FBSnapshotTestCase.h"

@interface FBSnapshotTestCase (WMFConvenience)

- (void)wmf_visuallyVerifyMultilineLabelWithText:(id)stringOrAttributedString;

@end
