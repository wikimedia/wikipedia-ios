//
//  UIWebView+SuppressSelection.m
//  Wikipedia
//
//  Created by Adam Baso on 2/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIWebView+WMFSuppressSelection.h"

@implementation UIWebView (WMF_SuppressSelection)

- (void)wmf_suppressSelection {
    self.userInteractionEnabled = NO;
    self.userInteractionEnabled = YES;
}

@end
