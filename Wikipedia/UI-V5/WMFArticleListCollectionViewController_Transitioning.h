//
//  WMFArticleListCollectionViewController_Transitioning.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/12/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleListCollectionViewController.h"
#import "WMFArticleListTransition.h"

@interface WMFArticleListCollectionViewController ()
<WMFArticleListTransitioning>

@property (nonatomic, strong, readonly) WMFArticleListTransition* listTransition;

@end
