#import <Foundation/Foundation.h>

//! Project version number for WMF.
FOUNDATION_EXPORT double WMFVersionNumber;

//! Project version string for WMF.
FOUNDATION_EXPORT const unsigned char WMFVersionString[];

#import <WMF/WMFAssertions.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/NSCharacterSet+WMFLinkParsing.h>
#import <WMF/NSURLComponents+WMFLinkParsing.h>
#import <WMF/WMFBlockDefinitions.h>
#import <WMF/WMFComparison.h>
#import <WMF/WMFHashing.h>
#import <WMF/WMFDeprecationMacros.h>
#import <WMF/NSProcessInfo+WMFOperatingSystemVersionChecks.h>
#import <WMF/NSArray+WMFMapping.h>
#import <WMF/NSURL+WMFExtras.h>
#import <WMF/WMFGCDHelpers.h>
#import <WMF/WMFLogging.h>
#import <WMF/WMFMath.h>
#import <WMF/WMFChange.h>
#import <WMF/WMFLocalization.h>
#import <WMF/NSError+WMFExtensions.h>
#import <WMF/WMFOutParamUtils.h>
#import <WMF/WMFRangeUtils.h>
#import <WMF/NSIndexSet+BKReduce.h>
#import <WMF/WMFGeometry.h>
#import <WMF/NSURL+WMFQueryParameters.h>
#import <WMF/NSFileManager+WMFExtendedFileAttributes.h>
#import <WMF/WMFTaskGroup.h>
#import <WMF/NSFileManager+WMFGroup.h>
#import <WMF/NSDateFormatter+WMFExtensions.h>
#import <WMF/NSDate+WMFRelativeDate.h>
#import <WMF/NSDictionary+WMFRequiredValueForKey.h>
#import <WMF/NSCalendar+WMFCommonCalendars.h>
#import <WMF/WMFNumberOfExtractCharacters.h>
#import <WMF/NSBundle+WMFInfoUtils.h>
#import <WMF/NSDictionary+WMFPageViewsSortedByDate.h>
#import <WMF/MWKLicense.h>
#import <WMF/NSString+SHA256.h>

#import <WMF/EXTScope.h>

#import <WMF/MWKDataStore.h>
#import <WMF/WMFExploreFeedContentController.h>

#import <WMF/MWKDataObject.h>
#import <WMF/MWKSiteDataObject.h>

#import <WMF/MWKSavedPageList.h>

#import <WMF/MWKRecentSearchEntry.h>
#import <WMF/MWKRecentSearchList.h>

#import <WMF/MWKImageInfo.h>
#import <WMF/NSString+WMFExtras.h>
#import <WMF/NSCharacterSet+WMFExtras.h>

#import <WMF/WikipediaAppUtils.h>
#import <WMF/NSRegularExpression+HTML.h>
#import <WMF/NSString+WMFHTMLParsing.h>
#import <WMF/WMFHTMLElement.h>
#import <WMF/WMFImageURLParsing.h>
#import <WMF/MWKLanguageLink.h>

#import <WMF/MWKLanguageLinkController.h>
#import <WMF/MWKLanguageFilter.h>

#import <WMF/UIScreen+WMFImageWidth.h>

#import <WMF/WMFNotificationsController.h>

#import <WMF/MWKLanguageLinkController_Private.h>
#import <WMF/WMFFaceDetectionCache.h>

#import <WMF/CIContext+WMFImageProcessing.h>
#import <WMF/CIDetector+WMFFaceDetection.h>

#import <WMF/WMFContentSource.h>
#import <WMF/WMFRelatedPagesContentSource.h>
#import <WMF/WMFNearbyContentSource.h>
#import <WMF/WMFContinueReadingContentSource.h>
#import <WMF/WMFFeedContentSource.h>
#import <WMF/WMFRandomContentSource.h>
#import <WMF/WMFAnnouncementsContentSource.h>
#import <WMF/WMFSuggestedEditsContentSource.h>

#import <WMF/WMFFeedContentFetcher.h>
#import <WMF/WMFFeedDayResponse.h>
#import <WMF/WMFFeedTopReadResponse.h>
#import <WMF/WMFFeedArticlePreview.h>
#import <WMF/WMFFeedImage.h>
#import <WMF/WMFFeedNewsStory.h>
#import <WMF/WMFFeedOnThisDayEvent.h>
#import <WMF/WMFOnThisDayEventsFetcher.h>

#import <WMF/CLLocation+WMFBearing.h>
#import <WMF/NSString+WMFDistance.h>
#import <WMF/CLLocation+WMFComparison.h>

#import <WMF/MWKLocationSearchResult.h>
#import <WMF/WMFLocationSearchResults.h>
#import <WMF/WMFLocationSearchFetcher.h>
#import <WMF/MWKLocationSearchResult.h>

#import <WMF/MWKSearchResult.h>

#import <WMF/WMFArticle+Extensions.h>
#import <WMF/WMFContentGroup+Extensions.h>
#import <WMF/WMFContent+CoreDataProperties.h>
#import <WMF/WMFKeyValue+CoreDataProperties.h>
#import <WMF/NSManagedObjectContext+WMFKeyValue.h>
#import <WMF/WMFAnnouncement.h>
#import <WMF/NSUserActivity+WMFExtensions.h>

//UI
#import <WMF/UIImageView+WMFImageFetching.h>
#import <WMF/UIColor+WMFStyle.h>
#import <WMF/UIImage+WMFStyle.h>
#import <WMF/UIView+WMFDefaultNib.h>
#import <WMF/FLAnimatedImage+SafeForSwift.h>
#import <WMF/WMFGradientView.h>
#import <WMF/WMFFeedContentDisplaying.h>
#import <WMF/WMFContentGroup+WMFFeedContentDisplaying.h>
#import <WMF/WMFLegacyFetcher.h>
#import <WMF/WMFLegacySerializer.h>
#import <WMF/MWKImageInfoFetcher.h>

//Deprecated
#import <WMF/MWKList.h>
#import <WMF/MWKList+Subclass.h>
