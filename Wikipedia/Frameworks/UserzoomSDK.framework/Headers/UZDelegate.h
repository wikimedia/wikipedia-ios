//
//  Filename: UZDelegate.h
//  Project:  sdk
//  Company:  UserZoom Technologies SL
//  Author:   Jordi Coscolla
//  Date:     20/8/15
//  Copyright:
//
//  Propietary and confidential
//
//  NOTICE: All information contained herein is, and remains the property
//  of UserZoom Technologies SL. The intellectual and technical concepts
//  contained herein are proprietary to UserZoom Technologies SL and
//  may be covered by U.S. and Foreign Patents, patents in process, and are
//  protected by trade secret or copyright law. Dissemination of this
//  information or reproduction of this material is strictly forbidden unless
//  prior written permission is obtained from UserZoom Technologies SL.
//
//  Summary:
//  =======
//
//  Delegate to be notified when the sdk change from states
//

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

-(void) event:(NSString*) eventName withData: (NSDictionary*) data;

@end