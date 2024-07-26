#import "WikiTextSectionUploader.h"
@import WMF;

NSString *const NSErrorUserInfoDisplayError = @"displayError";

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

- (void)prependToSectionID:(NSString *)sectionID
                         text:(NSString *)text
                forArticleURL:(NSURL *)articleURL
                      summary:(nullable NSString *)summary
             isMinorEdit:(BOOL)isMinorEdit
               baseRevID:(nullable NSNumber *)baseRevID
            editTags:(nullable NSArray<NSString *> *)editTags
                   completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion {

    NSString *title = articleURL.wmf_title;
    if (!title) {
        completion(nil, [WMFFetcher invalidParametersError]);
        return;
    }

    NSMutableDictionary *params =
    @{
      @"action": @"edit",
      @"prependtext": text,
      @"section": sectionID,
      @"summary": summary,
      @"title": articleURL.wmf_title,
      @"errorformat": @"html",
      @"errorsuselocal": @"1",
      @"format": @"json",
      @"formatversion": @"2",
      }
    .mutableCopy;

    if (isMinorEdit) {
        params[@"minor"] = @"1";
    }

    if (baseRevID) {
        params[@"baserevid"] = [NSString stringWithFormat:@"%@", baseRevID];
    }
    
    if (editTags && editTags.count > 0) {
        params[@"matags"] = [editTags componentsJoinedByString:@","];
    }

    [self updateWithArticleURL:articleURL parameters:params captchaWord:nil completion:completion];
}

- (void)uploadWikiText:(nullable NSString *)wikiText
         forArticleURL:(NSURL *)articleURL
               section:(nullable NSString *)section
               summary:(nullable NSString *)summary
           isMinorEdit:(BOOL)isMinorEdit
        addToWatchlist:(BOOL)addToWatchlist
             baseRevID:(nullable NSNumber *)baseRevID
             captchaId:(nullable NSString *)captchaId
           captchaWord:(nullable NSString *)captchaWord
              editTags:(nullable NSArray<NSString *> *)editTags
            completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion {
    
    wikiText = wikiText ? wikiText : @"";
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
      @"title": articleURL.wmf_title,
      @"errorformat": @"html",
      @"errorsuselocal": @"1",
      @"format": @"json",
      @"formatversion": @"2",
      }
    .mutableCopy;
    
    if (section) {
        params[@"section"] = section;
    }

    if (isMinorEdit) {
        params[@"minor"] = @"1";
    }

    if (addToWatchlist) {
        params[@"watchlist"] = @"watch";
    }
    
    if (baseRevID) {
        params[@"baserevid"] = [NSString stringWithFormat:@"%@", baseRevID];
    }

    if (captchaWord && captchaId) {
        params[@"captchaid"] = captchaId;
        params[@"captchaword"] = captchaWord;
    }
    
    if (editTags && editTags.count > 0) {
        params[@"matags"] = [editTags componentsJoinedByString:@","];
    }
    
    [self updateWithArticleURL:articleURL parameters:params captchaWord:captchaWord completion:completion];
}

- (void)updateWithArticleURL: (NSURL *)articleURL parameters: (NSDictionary<NSString *, NSString *> *)parameters captchaWord: (nullable NSString *)captchaWord completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion {
    
    [self performMediaWikiAPIPOSTWithCSRFTokenForURL:articleURL withBodyParameters:parameters completionHandler:^(NSDictionary<NSString *,id> * _Nullable responseObject, NSHTTPURLResponse * _Nullable response, NSError * _Nullable networkError) {

        if (networkError) {
            completion(nil, networkError);
            return;
        }

        // Fake out an error if non-dictionary response received.
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            responseObject = @{ @"error": @{@"info": @"WikiText upload data not found."} };
        }
        
        // Try handling block errors first, else fallback to legacy error handling
        [self resolveMediaWikiApiErrorFromResult:responseObject siteURL:articleURL completionHandler:^(MediaWikiAPIDisplayError *displayError) {
            
            if (displayError.messageHtml == nil) {
                [self handleErrorCodeLegacyWithResponseObject:responseObject captchaWord:captchaWord completion:completion];
                return;
            }
            
            WikiTextSectionUploaderErrorType errorType = WikiTextSectionUploaderErrorTypeUnknown;
            if ([displayError.code containsString:@"block"]) {
                errorType = WikiTextSectionUploaderErrorTypeBlocked;
            } else if ([displayError.code hasPrefix:@"abusefilter-warning"]) {
                errorType = WikiTextSectionUploaderErrorTypeAbuseFilterWarning;
            } else if ([displayError.code hasPrefix:@"abusefilter-disallowed"]) {
                errorType = WikiTextSectionUploaderErrorTypeAbuseFilterDisallowed;
            } else if ([displayError.code hasPrefix:@"abusefilter"]) {
                errorType = WikiTextSectionUploaderErrorTypeAbuseFilterOther;
            } else if ([displayError.code containsString:@"protectedpage"]) {
                errorType = WikiTextSectionUploaderErrorTypeProtectedPage;
            }
                
            if (errorType == WikiTextSectionUploaderErrorTypeUnknown) {
                [self handleErrorCodeLegacyWithResponseObject:responseObject captchaWord:captchaWord completion:completion];
                return;
            }
            
            NSError *error = nil;
            NSMutableDictionary *errorDict = [@{} mutableCopy];
            errorDict[NSErrorUserInfoDisplayError] = displayError;
            error = [NSError errorWithDomain:@"Upload Wikitext Op" code:errorType userInfo:errorDict];
            completion(responseObject, error);
        }];
    }];
    
}

- (void)handleErrorCodeLegacyWithResponseObject: (NSDictionary<NSString *,id> *)responseObject captchaWord: (nullable NSString *)captchaWord completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion {
    
    NSDictionary *resultDict = responseObject[@"edit"];
    NSString *result = resultDict[@"result"];
    
    NSError *error = nil;
    if (responseObject[@"error"]) {
        NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
        errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
        error = [NSError errorWithDomain:@"WikiText Uploader"
                                    code:WikiTextSectionUploaderErrorTypeServer
                                userInfo:errorDict];
    }

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
        }
    }

    completion(resultDict, error);
}
@end
