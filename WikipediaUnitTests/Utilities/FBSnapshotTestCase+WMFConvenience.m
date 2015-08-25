//
//  FBSnapshotTestCase+WMFConvenience.m
//  Wikipedia
//
//  Created by Monte Hurd on 8/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "FBSnapshotTestCase+WMFConvenience.h"
#import "XCTestCase+WMFLabelConvenience.h"

@implementation FBSnapshotTestCase (WMFConvenience)

- (void)wmf_visuallyVerifyMultilineLabelWithText:(id)stringOrAttributedString {
    FBSnapshotVerifyViewWithOptions([self wmf_getLabelConfiguredWithBlock:^(UILabel* label){
        if ([stringOrAttributedString isKindOfClass:[NSString class]]) {
            label.text = stringOrAttributedString;
        } else if ([stringOrAttributedString isKindOfClass:[NSAttributedString class]]) {
            label.attributedText = stringOrAttributedString;
        }
    }], nil, [NSSet setWithObject:@"_64"], 0);
}

@end
