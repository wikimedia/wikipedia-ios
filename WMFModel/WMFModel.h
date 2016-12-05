#import <Foundation/Foundation.h>

//! Project version number for WMFModel.
FOUNDATION_EXPORT double WMFModelVersionNumber;

//! Project version string for WMFModel.
FOUNDATION_EXPORT const unsigned char WMFModelVersionString[];

@import WMFUtilities;

#import "MWKDataStore.h"

#import "MWKDataObject.h"
#import "MWKSiteDataObject.h"

#import "MWKArticle.h"
#import "MWKSection.h"
#import "MWKSectionList.h"
#import "MWKImage.h"
#import "MWKUser.h"

#import "MWKHistoryList.h"
#import "MWKSavedPageList.h"

#import "MWKRecentSearchEntry.h"
#import "MWKRecentSearchList.h"

#import "WMFImageTagParser.h"
#import "WMFImageTag.h"
#import "WMFImageTag+TargetImageWidthURL.h"
#import "WMFImageTagList.h"
#import "WMFImageTagList+ImageURLs.h"

#import "MWKProtectionStatus.h"

#import "MWLanguageInfo.h"

#import "MWKImageInfo.h"
#import "NSString+WMFExtras.h"

#import "SDWebImageManager+WMFCacheRemoval.h"
#import "SDImageCache+WMFPersistentCache.h"
#import "WMFURLCache.h"

#import "MWKArticle+WMFSharing.h"
#import "MWKCitation.h"
#import "MWKImage+CanonicalFilenames.h"
#import "MWKImageInfo+MWKImageComparison.h"
#import "MWKSavedPageEntry+ImageMigration.h"
#import "MWKSavedPageListDataExportConstants.h"
#import "WikipediaAppUtils.h"
#import "NSString+WMFHTMLParsing.h"
#import "WMFImageURLParsing.h"
#import "WMFZeroConfiguration.h"
#import "WMFZeroConfigurationFetcher.h"
#import "MWKSectionMetaData.h"
#import "MWKLanguageLink.h"

#import "MWKLanguageLinkController.h"
#import "MWKLanguageFilter.h"
#import "WMFApiJsonResponseSerializer.h"
#import "MWKLanguageLinkResponseSerializer.h"
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFNetworkUtilities.h"
#import "FetcherBase.h"

#import "UIScreen+WMFImageWidth.h"
#import "NSURL+WMFMainPage.h"
#import "WMFAssetsFile.h"

#import "WMFNotificationsController.h"

#import "MWNetworkActivityIndicatorManager.h"

#import "MWKLanguageLinkController_Private.h"
#import "WMFFaceDetectionCache.h"

#import "CIContext+WMFImageProcessing.h"
#import "CIDetector+WMFFaceDetection.h"

#import "WMFContentSource.h"
#import "WMFRelatedPagesContentSource.h"
#import "WMFMainPageContentSource.h"
#import "WMFNearbyContentSource.h"
#import "WMFContinueReadingContentSource.h"
#import "WMFFeedContentSource.h"
#import "WMFRandomContentSource.h"

#import "WMFFeedContentFetcher.h"
#import "WMFFeedDayResponse.h"
#import "WMFFeedTopReadResponse.h"
#import "WMFFeedArticlePreview.h"
#import "WMFFeedImage.h"
#import "WMFFeedNewsStory.h"

#import "MWKSiteInfo.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFRandomArticleFetcher.h"

#import "WMFLocationManager.h"
#import "CLLocationManager+WMFLocationManagers.h"
#import "CLLocation+WMFBearing.h"
#import "NSString+WMFDistance.h"
#import "CLLocation+WMFComparison.h"

#import "WMFRelatedSearchFetcher.h"
#import "WMFRelatedSearchResults.h"
#import "WMFSearchResponseSerializer.h"

#import "MWKLocationSearchResult.h"
#import "WMFLocationSearchResults.h"
#import "WMFLocationSearchFetcher.h"
#import "MWKLocationSearchResult.h"

#import "EventLogger.h"
#import "EventLoggingFunnel.h"
#import "ReadingActionFunnel.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "AFHTTPRequestSerializer+WMFRequestHeaders.h"
#import "AFHTTPSessionManager+WMFDesktopRetry.h"
#import "WMFArticlePreviewFetcher.h"
#import "WMFBaseRequestSerializer.h"
#import "MWKSearchResult.h"
#import "NSDictionary+WMFCommonParams.h"

#import "WMFContentGroupDataStore.h"
#import "WMFArticleDataStore.h"

#import "WMFArticle+Extensions.h"
#import "WMFContentGroup+Extensions.h"


#import "NSUserActivity+WMFExtensions.h"

#import "PiwikTracker+WMFExtensions.h"

//Deprecated
#import "MWKHistoryEntry.h"
#import "MWKList.h"
#import "MWKList+Subclass.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "SessionSingleton.h"
#import "QueuesSingleton.h"
#import "MWKSavedPageEntry.h"
#import "WMFAnnouncementContentGroup.h"
