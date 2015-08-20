//  Created by Monte Hurd on 8/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <XCTest/XCTest.h>

@interface XCTestCase (WMFLabelConvenience)

/**
 *  Get testing label configured to 320 width and dynamic height based on length of text being shown.
 *  Useful for quick FBSnapshotTestCase test cases.
 *
 *  @param block This block is passed the label for easy configuration.
 *
 *  @return label
 */
- (UILabel*)wmf_getLabelConfiguredWithBlock:(void (^)(UILabel*))block;

@end
