//  Created by Monte Hurd on 7/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TabularScrollView.h"

typedef NS_ENUM (NSInteger, AbuseFilterAlertType) {
    ABUSE_FILTER_WARNING,
    ABUSE_FILTER_DISALLOW
};

@interface AbuseFilterAlert : TabularScrollView

- (id)initWithType:(AbuseFilterAlertType)alertType;

@property (nonatomic, readonly) AbuseFilterAlertType alertType;

@end
