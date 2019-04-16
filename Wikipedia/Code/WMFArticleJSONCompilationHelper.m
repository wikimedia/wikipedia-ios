#import "WMFArticleJSONCompilationHelper.h"
#import <WMF/MWKArticle.h>
#import <WMF/NSString+WMFHTMLParsing.h>
#import <WMF/WMFImageTag.h>
#import <WMF/WMFImageTag+TargetImageWidthURL.h>
#import <WMF/NSURL+WMFSchemeHandler.h>
#import <WMF/MWKSection.h>
#import <WMF/MWKSectionList.h>

@implementation WMFArticleJSONCompilationHelper

+ (nullable NSData *)jsonDataForArticle: (MWKArticle *)article withImageWidth: (NSInteger)imageWidth {
    MWKSectionList *sections = article.sections;
    NSInteger count = sections.count;
    NSMutableArray *sectionJSONs = [NSMutableArray arrayWithCapacity:count];
    NSURL *baseURL = article.url;
    for (MWKSection *section in sections) {
        NSString *sectionHTML = [self stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:section.text withBaseURL:baseURL targetImageWidth:imageWidth];
        if (!sectionHTML) {
            continue;
        }
        NSMutableDictionary *sectionJSON = [NSMutableDictionary dictionaryWithCapacity:5];
        sectionJSON[@"id"] = @(section.sectionId);
        sectionJSON[@"line"] = section.line;
        sectionJSON[@"level"] = section.level;
        sectionJSON[@"anchor"] = section.anchor;
        sectionJSON[@"text"] = sectionHTML;
        [sectionJSONs addObject:sectionJSON];
    }
    NSMutableDictionary *responseJSON = [NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableDictionary *mobileviewJSON = [NSMutableDictionary dictionaryWithCapacity:1];
    mobileviewJSON[@"sections"] = sectionJSONs;
    responseJSON[@"mobileview"] = mobileviewJSON;
    NSError *JSONError = nil;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:responseJSON options:0 error:&JSONError];
    return JSONData;
}

+ (NSString *)stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:(NSString *)HTMLString withBaseURL:(nullable NSURL *)baseURL targetImageWidth:(NSUInteger)targetImageWidth {
    
    //defensively copy
    HTMLString = [HTMLString copy];
    
    NSMutableString *newHTMLString = [NSMutableString stringWithString:@""];
    __block NSInteger location = 0;
    [HTMLString wmf_enumerateHTMLImageTagContentsWithHandler:^(NSString *imageTagContents, NSRange range) {
        //append the next chunk that we didn't match on to the new string
        NSString *nonMatchingStringToAppend = [HTMLString substringWithRange:NSMakeRange(location, range.location - location)];
        [newHTMLString appendString:nonMatchingStringToAppend];
        
        //update imageTagContents by changing the src, disabling the srcset, and adding other attributes used for scaling
        NSString *newImageTagContents = [self stringByUpdatingImageTagAttributesForProxyAndScalingInImageTagContents:imageTagContents withBaseURL:baseURL targetImageWidth:targetImageWidth];
        //append the updated image tag to the new string
        [newHTMLString appendString:[@[@"<img ", newImageTagContents, @">"] componentsJoinedByString:@""]];
        
        location = range.location + range.length;
    }];
    
    //append the final chunk of the original string
    if (HTMLString && location < HTMLString.length) {
        [newHTMLString appendString:[HTMLString substringWithRange:NSMakeRange(location, HTMLString.length - location)]];
    }
    
    return newHTMLString;
}

+ (NSString *)stringByUpdatingImageTagAttributesForProxyAndScalingInImageTagContents:(NSString *)imageTagContents withBaseURL:(NSURL *)baseURL targetImageWidth:(NSUInteger)targetImageWidth {
    
    NSMutableString *newImageTagContents = [imageTagContents mutableCopy];
    
    NSString *resizedSrc = nil;
    
    WMFImageTag *imageTag = [[WMFImageTag alloc] initWithImageTagContents:imageTagContents baseURL:baseURL];
    
    if (imageTag != nil) {
        NSString *src = imageTag.src;
        
        if ([imageTag isSizeLargeEnoughForGalleryInclusion]) {
            resizedSrc = [[imageTag URLForTargetWidth:targetImageWidth] absoluteString];
            if (resizedSrc) {
                src = resizedSrc;
            }
        }
        
        if (src) {
            NSString *srcWithProxy = [NSURL wmf_appSchemeURLForURLString:src].absoluteString;
            if (srcWithProxy) {
                NSString *newSrcAttribute = [@[@"src=\"", srcWithProxy, @"\""] componentsJoinedByString:@""];
                imageTag.src = newSrcAttribute;
                newImageTagContents = [imageTag.imageTagContents mutableCopy];
            }
        }
    }
    
    [newImageTagContents replaceOccurrencesOfString:@"srcset" withString:@"data-srcset-disabled" options:0 range:NSMakeRange(0, newImageTagContents.length)]; //disable the srcset since we put the correct resolution image in the src
    
    if (resizedSrc) {
        [newImageTagContents appendString:@" data-image-gallery=\"true\""]; //the javascript looks for this to know if it should attempt widening
    }
    
    return newImageTagContents;
}

@end
