#import "WikiTextSectionUploader.h"
#import "NSObject+WMFExtras.h"
@import WMF;

@implementation WikiTextSectionUploader

- (void)uploadWikiText:(nullable NSString *)wikiText
         forArticleURL:(NSURL *)articleURL
               section:(NSString *)section
               summary:(nullable NSString *)summary
             captchaId:(nullable NSString *)captchaId
           captchaWord:(nullable NSString *)captchaWord
                 token:(nullable NSString *)token
            completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion {
    
    wikiText = wikiText ? wikiText : @"";
    section = section ? section : @"";
    summary = summary ? summary : @"";
    token = token ? token : @"";
    NSString *title = articleURL.wmf_title;
    if (!title) {
        completion(nil, [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters userInfo:nil]);
        return;
    }
    
    NSMutableDictionary *params =
    @{
      @"action": @"edit",
      @"token": token,
      @"text": wikiText,
      @"summary": summary,
      @"section": section,
      @"title": articleURL.wmf_title,
      @"format": @"json",
      }
    .mutableCopy;
    
    if (captchaWord && captchaId) {
        params[@"captchaid"] = captchaId;
        params[@"captchaword"] = captchaWord;
    }

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [self performMediaWikiAPIPOSTForURL:articleURL withBodyParameters:params completionHandler:^(NSDictionary<NSString *,id> * _Nullable responseObject, NSHTTPURLResponse * _Nullable response, NSError * _Nullable networkError) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        if (networkError) {
            completion(nil, networkError);
            return;
        }
            //NSLog(@"JSON: %@", responseObject);

            // Fake out an error if non-dictionary response received.
            if (![responseObject isDict]) {
                responseObject = @{ @"error": @{@"info": @"WikiText upload data not found."} };
            }

            //NSLog(@"ACCT CREATION DATA RETRIEVED = %@", responseObject);

            // Handle case where response is received, but API reports error.
            NSError *error = nil;
            if (responseObject[@"error"]) {
                NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                error = [NSError errorWithDomain:@"WikiText Uploader"
                                            code:WIKITEXT_UPLOAD_ERROR_SERVER
                                        userInfo:errorDict];
            }

            NSDictionary *resultDict = responseObject[@"edit"];
            NSString *result = resultDict[@"result"];

            if (!error && !result) {
                NSMutableDictionary *errorDict = [@{} mutableCopy];
                errorDict[NSLocalizedDescriptionKey] = WMFLocalizedStringWithDefaultValue(@"wikitext-upload-result-unknown", nil, nil, @"Unable to determine wikitext upload result.", @"Alert text shown when the result of saving section wikitext changes is unknown");

                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                error = [NSError errorWithDomain:@"Upload Wikitext Op" code:WIKITEXT_UPLOAD_ERROR_UNKNOWN userInfo:errorDict];
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
                    error = [NSError errorWithDomain:@"Upload Wikitext Op" code:WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA userInfo:errorDict];
                } else if (responseObject[@"edit"][@"code"]) {
                    NSString *abuseFilterCode = responseObject[@"edit"][@"code"];
                    WikiTextSectionUploaderErrors errorType = WIKITEXT_UPLOAD_ERROR_UNKNOWN;

                    if ([abuseFilterCode hasPrefix:@"abusefilter-warning"]) {
                        errorType = WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING;
                    } else if ([abuseFilterCode hasPrefix:@"abusefilter-disallowed"]) {
                        errorType = WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED;
                    } else if ([abuseFilterCode hasPrefix:@"abusefilter"]) {
                        errorType = WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER;
                    }

                    switch (errorType) {
                        case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING:
                        case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED:
                        case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER: {
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
