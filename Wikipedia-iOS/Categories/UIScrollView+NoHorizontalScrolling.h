//  Created by Monte Hurd on 4/2/14.

#import <UIKit/UIKit.h>

// To restrict horizonal scrolling in a robust way,
// even when web view content is appended, KVO observe
// the scrollView's contentSize property and call
// "preventHorizontalScrolling" whenever contentSize
// changes.

// Based on: http://stackoverflow.com/a/8214325

@interface UIScrollView (NoHorizontalScrolling)

-(void)preventHorizontalScrolling;

@end
