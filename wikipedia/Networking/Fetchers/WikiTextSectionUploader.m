//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikiTextSectionUploader.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "WikipediaAppUtils.h"

@interface WikiTextSectionUploader()

@property (strong, nonatomic) NSString *wikiText;
@property (strong, nonatomic) MWKTitle *title;
@property (strong, nonatomic) NSString *section;
@property (strong, nonatomic) NSString *summary;
@property (strong, nonatomic) NSString *captchaId;
@property (strong, nonatomic) NSString *captchaWord;
@property (strong, nonatomic) NSString *token;

@end

@implementation WikiTextSectionUploader

-(instancetype)initAndUploadWikiText: (NSString *)wikiText
                        forPageTitle: (MWKTitle *)title
                             section: (NSString *)section
                             summary: (NSString *)summary
                           captchaId: (NSString *)captchaId
                         captchaWord: (NSString *)captchaWord
                               token: (NSString *)token
                         withManager: (AFHTTPRequestOperationManager *)manager
                  thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate
{
    self = [super init];
    if (self) {

        self.wikiText = wikiText ? wikiText : @"";
        self.title = title;
        assert(title != nil);
        self.section = section ? section : @"";
        self.summary = summary ? summary : @"";
        self.captchaId = captchaId ? captchaId : @"";
        self.captchaWord = captchaWord ? captchaWord : @"";
        self.token = token ? token : @"";

        self.fetchFinishedDelegate = delegate;
        [self uploadWithManager: manager];
    }
    return self;
}

- (void)uploadWithManager: (AFHTTPRequestOperationManager *)manager
{
    NSURL *url = [[SessionSingleton sharedInstance] urlForLanguage:self.title.site.language];

    NSDictionary *params = [self getParams];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager POST:url.absoluteString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Fake out an error if non-dictionary response received.
        if(![responseObject isDict]){
            responseObject = @{@"error": @{@"info": @"WikiText upload data not found."}};
        }
        
        //NSLog(@"ACCT CREATION DATA RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"WikiText Uploader"
                                        code: WIKITEXT_UPLOAD_ERROR_SERVER
                                    userInfo: errorDict];
        }


        NSDictionary *resultDict = responseObject[@"edit"];
        NSString *result = resultDict[@"result"];
        
        if (!error && !result) {
            NSMutableDictionary *errorDict = [@{} mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = MWLocalizedString(@"wikitext-upload-result-unknown", nil);
            
            // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
            error = [NSError errorWithDomain:@"Upload Wikitext Op" code:WIKITEXT_UPLOAD_ERROR_UNKNOWN userInfo:errorDict];
        }
        
        if (!error && result && [result isEqualToString:@"Failure"]) {
            
            
            if(responseObject[@"edit"][@"captcha"]){
                NSMutableDictionary *errorDict = [@{} mutableCopy];
                
                errorDict[NSLocalizedDescriptionKey] = (self.captchaWord && (self.captchaWord.length > 0)) ?
                MWLocalizedString(@"wikitext-upload-captcha-error", nil)
                :
                MWLocalizedString(@"wikitext-upload-captcha-needed", nil)
                ;
                
                // Make the capcha id and url available from the error.
                errorDict[@"captchaId"] = responseObject[@"edit"][@"captcha"][@"id"];
                errorDict[@"captchaUrl"] = responseObject[@"edit"][@"captcha"][@"url"];
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                error = [NSError errorWithDomain:@"Upload Wikitext Op" code:WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA userInfo:errorDict];
            }else if(responseObject[@"edit"][@"code"]){
                
                NSString *abuseFilterCode = responseObject[@"edit"][@"code"];
                WikiTextSectionUploaderErrors errorType = WIKITEXT_UPLOAD_ERROR_UNKNOWN;
                
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
                        
                        errorDict[NSLocalizedDescriptionKey] = responseObject[@"edit"][@"info"];
                        
                        // Make the verbose warning available from the error.
                        errorDict[@"warning"] = responseObject[@"edit"][@"warning"];
                        errorDict[@"code"] = abuseFilterCode;
                        
                        // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                        error = [NSError errorWithDomain:@"Upload Wikitext Op" code:errorType userInfo:errorDict];
                    }
                        break;
                        
                    default:
                        break;
                }
            }
        }

        [self finishWithError: error
                  fetchedData: resultDict];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"ACCT CREATION TOKEN FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSMutableDictionary *)getParams
{
    NSString *tokenToUse = @"+\\";
    if (self.token && (self.token.length > 0)) {
        tokenToUse = self.token;
    }

    NSMutableDictionary *params =
    @{
      @"action": @"edit",
      @"token": tokenToUse,
      @"text": self.wikiText,
      @"summary": self.summary,
      @"section": self.section,
      @"title": self.title.prefixedText,
      @"format": @"json"
      }.mutableCopy;
    
    if (self.captchaWord) {
        params[@"captchaid"] = self.captchaId;
        params[@"captchaword"] = self.captchaWord;
    }

    return params;
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING PAGE HISTORY FETCHER!");
}
*/

@end
