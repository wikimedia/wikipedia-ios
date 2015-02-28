//  Created by Monte Hurd on 2/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class PaddedLabel, SearchResultsController;

@interface WMFReadMoreViewController : UIViewController

@property (strong, nonatomic) NSString *searchString;

@property (strong, nonatomic) NSArray *articlesToExcludeFromResults;

-(void)search;

@end
