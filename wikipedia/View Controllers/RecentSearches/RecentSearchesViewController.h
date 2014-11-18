//  Created by Monte Hurd on 11/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "Defines.h"

@interface RecentSearchesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic, readonly) NSNumber *recentSearchesItemCount;

-(void)saveTerm: (NSString *)term
      forDomain: (NSString *)domain
           type: (SearchType)searchType;

@end
