//
//  EditFunnel.h
//  Wikipedia
//
//  Created by Brion on 5/28/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "EventLoggingFunnel.h"

@interface EditFunnel : EventLoggingFunnel

@property NSString *editSessionToken;

-(id)init;
-(void)logStart;
-(void)logPreview;
-(void)logSavedRevision:(int)revID;
-(void)logLoginAttempt;
-(void)logLoginSuccess;
-(void)logLoginFailure;
-(void)logCaptchaShown;
-(void)logCaptchaFailure;
-(void)logAbuseFilterWarning:(NSString *)code;
-(void)logAbuseFilterError:(NSString *)code;
-(void)logAbuseFilterWarningIgnore:(NSString *)code;
-(void)logAbuseFilterWarningBack:(NSString *)code;
-(void)logSaveAnonExplicit;
-(void)logError:(NSString *)code;

@end
