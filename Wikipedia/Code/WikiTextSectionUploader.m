#import "WikiTextSectionUploader.h"
@import WMF;

@implementation WikiTextSectionUploader

- (void)addSectionWithSummary:(NSString *)summary
                text:(NSString *)text
         forArticleURL:(NSURL *)articleURL
            completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion {
    
    NSString *title = articleURL.wmf_title;
    if (!title) {
        completion(nil, [WMFFetcher invalidParametersError]);
        return;
    }
    
    NSMutableDictionary *params =
    @{
      @"action": @"edit",
      @"text": text,
      @"summary": summary,
      @"section": @"new",
      @"title": articleURL.wmf_title,
      @"format": @"json"
      }
    .mutableCopy;
    
    [self updateWithArticleURL:articleURL parameters:params captchaWord:nil completion:completion];
}

- (void)appendToSection:(NSString *)section
                         text:(NSString *)text
                forArticleURL:(NSURL *)articleURL
                   completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion {
    
    NSString *title = articleURL.wmf_title;
    if (!title) {
        completion(nil, [WMFFetcher invalidParametersError]);
        return;
    }
    
    NSMutableDictionary *params =
    @{
      @"action": @"edit",
      @"appendtext": text,
      @"section": section,
      @"title": articleURL.wmf_title,
      @"format": @"json"
      }
    .mutableCopy;
    
    [self updateWithArticleURL:articleURL parameters:params captchaWord:nil completion:completion];
}

- (void)uploadWikiText:(nullable NSString *)wikiText
         forArticleURL:(NSURL *)articleURL
               section:(NSString *)section
               summary:(nullable NSString *)summary
           isMinorEdit:(BOOL)isMinorEdit
        addToWatchlist:(BOOL)addToWatchlist
             captchaId:(nullable NSString *)captchaId
           captchaWord:(nullable NSString *)captchaWord
            completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion {
    
    wikiText = wikiText ? wikiText : @"";
    section = section ? section : @"";
    summary = summary ? summary : @"";
    NSString *title = articleURL.wmf_title;
    if (!title) {
        completion(nil, [WMFFetcher invalidParametersError]);
        return;
    }
    
    NSMutableDictionary *params =
    @{
      @"action": @"edit",
      @"text": wikiText,
      @"summary": summary,
      @"section": section,
      @"title": articleURL.wmf_title,
      @"format": @"json",
      }
    .mutableCopy;

    if (isMinorEdit) {
        params[@"minor"] = @"1";
    }

    if (addToWatchlist) {
        params[@"watchlist"] = @"watch";
    }

    if (captchaWord && captchaId) {
        params[@"captchaid"] = captchaId;
        params[@"captchaword"] = captchaWord;
    }
    
    [self updateWithArticleURL:articleURL parameters:params captchaWord:captchaWord completion:completion];
}

- (void)updateWithArticleURL: (NSURL *)articleURL parameters: (NSDictionary<NSString *, NSString *> *)parameters captchaWord: (nullable NSString *)captchaWord completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion {
    
    [self performMediaWikiAPIPOSTWithCSRFTokenForURL:articleURL withBodyParameters:parameters completionHandler:^(NSDictionary<NSString *,id> * _Nullable responseObject, NSHTTPURLResponse * _Nullable response, NSError * _Nullable networkError) {

        if (networkError) {
            completion(nil, networkError);
            return;
        }
            //NSLog(@"JSON: %@", responseObject);

            // Fake out an error if non-dictionary response received.
            if (![responseObject isKindOfClass:[NSDictionary class]]) {
                responseObject = @{ @"error": @{@"info": @"WikiText upload data not found."} };
            }

            //NSLog(@"ACCT CREATION DATA RETRIEVED = %@", responseObject);

            // Handle case where response is received, but API reports error.
            NSError *error = nil;
            if (responseObject[@"error"]) {
                NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                error = [NSError errorWithDomain:@"WikiText Uploader"
                                            code:WikiTextSectionUploaderErrorTypeServer
                                        userInfo:errorDict];
            }

            NSDictionary *resultDict = responseObject[@"edit"];
            NSString *result = resultDict[@"result"];

            if (!error && !result) {
                NSMutableDictionary *errorDict = [@{} mutableCopy];
                errorDict[NSLocalizedDescriptionKey] = WMFLocalizedStringWithDefaultValue(@"wikitext-upload-result-unknown", nil, nil, @"Unable to determine wikitext upload result.", @"Alert text shown when the result of saving section wikitext changes is unknown");

                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                error = [NSError errorWithDomain:@"Upload Wikitext Op" code:WikiTextSectionUploaderErrorTypeUnknown userInfo:errorDict];
            }

            if (!error && result && [result isEqualToString:@"Failure"]) {
                if (responseObject[@"edit"][@"captcha"]) {
                    NSMutableDictionary *errorDict = [@{} mutableCopy];

                    errorDict[NSLocalizedDescriptionKey] = (captchaWord && (captchaWord.length > 0)) ? WMFLocalizedStringWithDefaultValue(@"wikitext-upload-captcha-error", nil, nil, @"CAPTCHA verification error.", @"Alert text shown when section wikitext upload captcha fails")
                                                                                                               : WMFLocalizedStringWithDefaultValue(@"wikitext-upload-captcha-needed", nil, nil, @"Need CAPTCHA verification.", @"Alert text shown when section wikitext upload captcha is required");

                    // Make the capcha id and url available from the error.
                    errorDict[@"captchaId"] = responseObject[@"edit"][@"captcha"][@"id"];
                    errorDict[@"captchaUrl"] = responseObject[@"edit"][@"captcha"][@"url"];

                    // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                    error = [NSError errorWithDomain:@"Upload Wikitext Op" code:WikiTextSectionUploaderErrorTypeNeedsCaptcha userInfo:errorDict];
                } else if (responseObject[@"edit"][@"code"]) {
                    NSString *abuseFilterCode = responseObject[@"edit"][@"code"];
                    WikiTextSectionUploaderErrorType errorType = WikiTextSectionUploaderErrorTypeUnknown;

                    if ([abuseFilterCode hasPrefix:@"abusefilter-warning"]) {
                        errorType = WikiTextSectionUploaderErrorTypeAbuseFilterWarning;
                    } else if ([abuseFilterCode hasPrefix:@"abusefilter-disallowed"]) {
                        errorType = WikiTextSectionUploaderErrorTypeAbuseFilterDisallowed;
                    } else if ([abuseFilterCode hasPrefix:@"abusefilter"]) {
                        errorType = WikiTextSectionUploaderErrorTypeAbuseFilterOther;
                    }

                    switch (errorType) {
                        case WikiTextSectionUploaderErrorTypeAbuseFilterWarning:
                        case WikiTextSectionUploaderErrorTypeAbuseFilterDisallowed:
                        case WikiTextSectionUploaderErrorTypeAbuseFilterOther: {
                            NSMutableDictionary *errorDict = [@{} mutableCopy];

                            errorDict[NSLocalizedDescriptionKey] = responseObject[@"edit"][@"info"];

                            // Make the verbose warning available from the error.
                            errorDict[@"warning"] = responseObject[@"edit"][@"warning"];
                            errorDict[@"code"] = abuseFilterCode;

                            // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                            error = [NSError errorWithDomain:@"Upload Wikitext Op" code:errorType userInfo:errorDict];
                        } break;

                        default:
                            break;
                    }
                }
            }

        completion(resultDict, error);
    }];
}
@end
