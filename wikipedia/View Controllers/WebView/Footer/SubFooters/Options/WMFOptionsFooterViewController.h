//  Created by Monte Hurd on 2/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface WMFOptionsFooterViewController : UIViewController

-(void)updateLanguageCount:(NSInteger)count;

-(void)updateLastModifiedDate:(NSDate *)date userName:(NSString *)userName;

@end
