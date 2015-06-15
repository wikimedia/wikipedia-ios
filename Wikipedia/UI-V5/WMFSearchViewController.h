//
//  WMFSearchViewController.h
//  Wikipedia
//
//  Created by Corey Floyd on 6/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

@protocol WMFSearchViewControllerDelegate;

@interface WMFSearchViewController : UIViewController

@property(nonatomic, weak) id<WMFSearchViewControllerDelegate> delegate;
@end


@protocol WMFSearchViewControllerDelegate <NSObject>

- (void)searchControllerSearchDidStartSearching:(WMFSearchViewController*)controller;

- (void)searchControllerSearchDidFinishSearching:(WMFSearchViewController*)controller;

@end
