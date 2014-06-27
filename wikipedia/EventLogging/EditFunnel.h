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
/**
 * Parameter should be one of the string keys defined at
 * https://meta.wikimedia.org/wiki/Schema_talk:MobileWikiAppEdit#Schema_missing_enum_for_editSummaryTapped
 */
-(void)logEditSummaryTap:(NSString *)editSummaryTapped;
-(void)logSavedRevision:(int)revID;
-(void)logCaptchaShown;
-(void)logCaptchaFailure;
-(void)logAbuseFilterWarning:(NSString *)code;
-(void)logAbuseFilterError:(NSString *)code;
-(void)logAbuseFilterWarningIgnore:(NSString *)code;
-(void)logAbuseFilterWarningBack:(NSString *)code;
-(void)logSaveAttempt; // @FIXME USE
-(void)logError:(NSString *)code;

@end
