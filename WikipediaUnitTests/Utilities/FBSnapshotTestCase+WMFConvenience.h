//  Created by Monte Hurd on 8/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "FBSnapshotTestCase.h"

@interface FBSnapshotTestCase (WMFConvenience)

- (void)wmf_visuallyVerifyMultilineLabelWithText:(id)stringOrAttributedString;

- (void)wmf_visuallyVerifyCellWithIdentifier:(NSString*)identifier
                               fromTableView:(UITableView*)tableView
                         configuredWithBlock:(void (^)(UITableViewCell*))block;

@end
