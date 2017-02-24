@import KVOController;
@import UIKit;
@import BlocksKit;

//! Project version number for WMF.
FOUNDATION_EXPORT double WMFVersionNumber;

//! Project version string for WMF.
FOUNDATION_EXPORT const unsigned char WMFVersionString[];

#import "WMFAssertions.h"
#import "NSURL+WMFLinkParsing.h"
#import "NSURLComponents+WMFLinkParsing.h"
#import "WMFBlockDefinitions.h"
#import "WMFComparison.h"
#import "WMFHashing.h"
#import "WMFDeprecationMacros.h"
#import "NSProcessInfo+WMFOperatingSystemVersionChecks.h"
#import "NSArray+WMFMapping.h"
#import "NSMutableArray+WMFSafeAdd.h"
#import "NSMutableSet+WMFSafeAdd.h"
#import "NSDictionary+WMFExtensions.h"
#import "NSURL+WMFExtras.h"
#import "WMFGCDHelpers.h"
#import "WMFLogging.h"
#import "WMFDirectoryPaths.h"
#import "WMFLocalization.h"
#import "WMFMath.h"
#import "NSError+WMFExtensions.h"
#import "WMFOutParamUtils.h"
#import "WMFRangeUtils.h"
#import "NSArray+BKIndex.h"
#import "NSIndexSet+BKReduce.h"
#import "NSMutableDictionary+WMFMaybeSet.h"
#import "WMFGeometry.h"
#import "NSURL+WMFProxyServer.h"
#import "NSURL+WMFQueryParameters.h"
#import "NSFileManager+WMFExtendedFileAttributes.h"
#import "WMFTaskGroup.h"
#import "NSFileManager+WMFGroup.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "NSDate+WMFRelativeDate.h"
#import "NSDictionary+WMFRequiredValueForKey.h"
#import "NSCalendar+WMFCommonCalendars.h"
#import "WMFNumberOfExtractCharacters.h"
#import "NSBundle+WMFInfoUtils.h"
#import "NSDictionary+WMFPageViewsSortedByDate.h"

#import "EXTScope.h"

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
#import "WMFKeyValue+CoreDataProperties.h"

#import "NSUserActivity+WMFExtensions.h"

#import "PiwikTracker+WMFExtensions.h"

//UI
#import "UIImageView+WMFImageFetching.h"
#import "UIColor+WMFStyle.h"
#import "UIImage+WMFStyle.h"
#import "UIImageView+WMFPlaceholder.h"
#import "UIColor+WMFHexColor.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"
#import "UIView+WMFDefaultNib.h"

//Deprecated
#import "MWKHistoryEntry.h"
#import "MWKList.h"
#import "MWKList+Subclass.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "SessionSingleton.h"
#import "QueuesSingleton.h"
#import "MWKSavedPageEntry.h"
#import "WMFLegacyContentGroup.h"

