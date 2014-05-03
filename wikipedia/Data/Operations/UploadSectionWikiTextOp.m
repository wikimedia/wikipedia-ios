//  Created by Monte Hurd on 1/16/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UploadSectionWikiTextOp.h"
#import "WikipediaAppUtils.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"

@implementation UploadSectionWikiTextOp

- (id)initForPageTitle: (NSString *)title
                domain: (NSString *)domain
               section: (NSString *)section
              wikiText: (NSString *)wikiText
               summary: (NSString *)summary
             captchaId: (NSString *)captchaId
           captchaWord: (NSString *)captchaWord
       completionBlock: (void (^)(NSString *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {
    
        __weak UploadSectionWikiTextOp *weakSelf = self;
        self.aboutToStart = ^{
            [[MWNetworkActivityIndicatorManager sharedManager] push];
            
            NSMutableDictionary *editTokens = [SessionSingleton sharedInstance].keychainCredentials.editTokens;
            NSString *editToken = editTokens[domain];
            
            if (!editToken) editToken  = @"+\\";
            
            NSMutableDictionary *parameters = [@{
                                                 @"action": @"edit",
                                                 @"token": editToken,
                                                 @"text": wikiText,
                                                 @"summary": summary,
                                                 @"section": section,
                                                 @"title": title,
                                                 @"format": @"json"
                                                 } mutableCopy];
            
            if (captchaWord) {
                parameters[@"captchaid"] = captchaId;
                parameters[@"captchaword"] = captchaWord;
            }
            
            //NSLog(@"parameters = %@", parameters);
            //weakSelf.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:@"127.0.0.1"] parameters: parameters];
            //return;
            
            weakSelf.request = [NSURLRequest postRequestWithURL: [[SessionSingleton sharedInstance] urlForDomain:domain]
                                                     parameters: parameters];
        };
        self.completionBlock = ^(){
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            
            if(weakSelf.isCancelled){
                cancelledBlock(weakSelf.error);
                return;
            }

            //NSLog(@"%@", weakSelf.jsonRetrieved);
            // Check for error retrieving section zero data.
            if(weakSelf.jsonRetrieved[@"error"]){
                NSMutableDictionary *errorDict = [weakSelf.jsonRetrieved[@"error"] mutableCopy];
                
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Upload Wikitext Op" code:WIKITEXT_UPLOAD_ERROR_SERVER userInfo:errorDict];
            }
         
            NSString *result = weakSelf.jsonRetrieved[@"edit"][@"result"];

            if (!weakSelf.error && !result) {
                NSMutableDictionary *errorDict = [@{} mutableCopy];
                errorDict[NSLocalizedDescriptionKey] = MWLocalizedString(@"wikitext-upload-result-unknown", nil);
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Upload Wikitext Op" code:WIKITEXT_UPLOAD_ERROR_UNKNOWN userInfo:errorDict];
            }

            if (!weakSelf.error && result && [result isEqualToString:@"Failure"]) {
            
            
                if(weakSelf.jsonRetrieved[@"edit"][@"captcha"]){
                    NSMutableDictionary *errorDict = [@{} mutableCopy];
                    
                    errorDict[NSLocalizedDescriptionKey] = (captchaWord && (captchaWord.length > 0)) ?
                    MWLocalizedString(@"wikitext-upload-captcha-error", nil)
                    :
                    MWLocalizedString(@"wikitext-upload-captcha-needed", nil)
                    ;
                    
                    // Make the capcha id and url available from the error.
                    errorDict[@"captchaId"] = weakSelf.jsonRetrieved[@"edit"][@"captcha"][@"id"];
                    errorDict[@"captchaUrl"] = weakSelf.jsonRetrieved[@"edit"][@"captcha"][@"url"];
                    
                    // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                    weakSelf.error = [NSError errorWithDomain:@"Upload Wikitext Op" code:WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA userInfo:errorDict];
                }else if(weakSelf.jsonRetrieved[@"edit"][@"code"]){

                    NSString *abuseFilterCode = weakSelf.jsonRetrieved[@"edit"][@"code"];
                    UploadSectionWikiTextOpErrors errorType = WIKITEXT_UPLOAD_ERROR_UNKNOWN;

                    if([abuseFilterCode hasPrefix:@"abusefilter-warning"]){
                        errorType = WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING;
                    }else if([abuseFilterCode hasPrefix:@"abusefilter-disallowed"]){
                        errorType = WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED;
                    }else if([abuseFilterCode hasPrefix:@"abusefilter"]){
                        errorType = WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER;
                    }
                    
                    switch (errorType) {
                        case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING:
                        case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED:
                        case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER:
                            {
                                NSMutableDictionary *errorDict = [@{} mutableCopy];
                                
                                errorDict[NSLocalizedDescriptionKey] = weakSelf.jsonRetrieved[@"edit"][@"info"];
                                
                                // Make the verbose warning available from the error.
                                errorDict[@"warning"] = weakSelf.jsonRetrieved[@"edit"][@"warning"];
                                
                                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                                weakSelf.error = [NSError errorWithDomain:@"Upload Wikitext Op" code:errorType userInfo:errorDict];
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
            
            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }

            completionBlock(result);
        };
    }
    return self;
}

@end
