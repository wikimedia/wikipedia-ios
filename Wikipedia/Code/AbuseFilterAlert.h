#import "TabularScrollView.h"

typedef NS_ENUM(NSInteger, AbuseFilterAlertType) {
    ABUSE_FILTER_WARNING,
    ABUSE_FILTER_DISALLOW
};

@interface AbuseFilterAlert : TabularScrollView

- (id)initWithType:(AbuseFilterAlertType)alertType;

@property (nonatomic, readonly) AbuseFilterAlertType alertType;

@end
