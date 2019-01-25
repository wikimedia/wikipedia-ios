#import "TabularScrollView.h"

typedef NS_ENUM(NSInteger, AbuseFilterAlertType) {
    AbuseFilterAlertTypeWarning,
    AbuseFilterAlertTypeDisallow
};

NS_ASSUME_NONNULL_BEGIN

@interface AbuseFilterAlert : TabularScrollView

- (id)initWithType:(AbuseFilterAlertType)alertType;

@property (nonatomic, readonly) AbuseFilterAlertType alertType;

@end

NS_ASSUME_NONNULL_END
