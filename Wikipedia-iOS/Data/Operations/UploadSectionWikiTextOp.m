//  Created by Monte Hurd on 1/16/14.

#import "UploadSectionWikiTextOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"

@implementation UploadSectionWikiTextOp

- (id)initForPageTitle: (NSString *)title
                domain: (NSString *)domain
               section: (NSNumber *)section
              wikiText: (NSString *)wikiText
              captchaId: (NSString *)captchaId
              captchaWord: (NSString *)captchaWord
       completionBlock: (void (^)(NSString *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {
        NSMutableDictionary *parameters = [@{
                                             @"action": @"edit",
                                             @"token": @"+\\",
                                             @"text": wikiText,
                                             @"section": section,
                                             @"title": title,
                                             @"format": @"json"
                                             } mutableCopy];

        if (captchaWord) {
            parameters[@"captchaid"] = captchaId;
            parameters[@"captchaword"] = captchaWord;
        }

        //NSLog(@"parameters = %@", parameters);

        self.request = [NSURLRequest postRequestWithURL: [[SessionSingleton sharedInstance] urlForDomain:domain]
                                             parameters: parameters];
        __weak UploadSectionWikiTextOp *weakSelf = self;
        self.aboutToStart = ^{
            [[MWNetworkActivityIndicatorManager sharedManager] push];
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
                errorDict[NSLocalizedDescriptionKey] = @"Unable to determine wikitext upload result.";
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Upload Wikitext Op" code:WIKITEXT_UPLOAD_ERROR_UNKNOWN userInfo:errorDict];
            }

            if (!weakSelf.error && result && [result isEqualToString:@"Failure"] && weakSelf.jsonRetrieved[@"edit"][@"captcha"]) {
                NSMutableDictionary *errorDict = [@{} mutableCopy];
                
                errorDict[NSLocalizedDescriptionKey] = (captchaWord && (captchaWord.length > 0)) ?
                    @"Captcha verification error."
                    :
                    @"Need captcha verification."
                ;
                
                // Make the capcha id and url available from the error.
                errorDict[@"captchaId"] = weakSelf.jsonRetrieved[@"edit"][@"captcha"][@"id"];
                errorDict[@"captchaUrl"] = weakSelf.jsonRetrieved[@"edit"][@"captcha"][@"url"];
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Upload Wikitext Op" code:WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA userInfo:errorDict];
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
