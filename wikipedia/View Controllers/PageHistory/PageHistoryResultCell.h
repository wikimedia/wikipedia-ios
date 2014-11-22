//  Created by Monte Hurd on 11/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@class PageHistoryLabel;

@interface PageHistoryResultCell : UITableViewCell

-(void)setName: (NSString *)name
          time: (NSString *)time
         delta: (NSNumber *)delta
          icon: (NSString *)icon
       summary: (NSString *)summary
     separator: (BOOL)separator;

@end
