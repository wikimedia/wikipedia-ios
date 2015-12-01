//  Created by Monte Hurd on 4/2/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

// To restrict horizonal scrolling in a robust way,
// even when web view content is appended, KVO observe
// the scrollView's contentSize property and call
// "preventHorizontalScrolling" whenever contentSize
// changes.

// Based on: http://stackoverflow.com/a/8214325

@interface UIScrollView (NoHorizontalScrolling)

- (void)preventHorizontalScrolling;

@end
