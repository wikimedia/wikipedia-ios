#import <Foundation/Foundation.h>

// States sent from this delegate
#define EVENT_STATE_CHANGED @"stateChanged"

// keys for the dictionary data
#define EVENT_NEW_STATE @"state"

// values for the dictionary on key "state"
#define STATE_ON_QUESTIONNAIRE @"onQuestionnaire"
#define STATE_ON_TASK @"onTask"
#define STATE_ON_INTERCEPT @"onIntercept"
#define STATE_ON_FINALIZE @"onFinalized"
#define STATE_ON_FINALIZE_BY_USER @"onFinalizedByUser"

@protocol UZDelegate <NSObject>

- (void)event:(NSString *)eventName withData:(NSDictionary *)data;

@end