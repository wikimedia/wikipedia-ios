#ifndef WMFModel_global_h
#define WMFModel_global_h

@import WMFUtilities;

#import <WMFModel/WMFBaseDataStore.h>
#import <WMFModel/MWKDataStore.h>
#import <WMFModel/WMFContentGroupDataStore.h>

#import <WMFModel/WMFDataBaseDataSource.h>
#import <WMFModel/MWKDataStore+WMFDataSources.h>

#import <WMFModel/SessionSingleton.h>
#import <WMFModel/QueuesSingleton.h>

#import <WMFModel/MWKDataObject.h>
#import <WMFModel/MWKSiteDataObject.h>

#import <WMFModel/MWKSite.h>
#import <WMFModel/MWKTitle.h>
#import <WMFModel/MWKArticle.h>
#import <WMFModel/MWKSection.h>
#import <WMFModel/MWKSectionList.h>
#import <WMFModel/MWKImage.h>
#import <WMFModel/MWKUser.h>

#import <WMFModel/MWKList.h>

#import <WMFModel/MWKHistoryEntry.h>
#import <WMFModel/MWKHistoryList.h>

#import <WMFModel/MWKSavedPageEntry.h>
#import <WMFModel/MWKSavedPageList.h>

#import <WMFModel/MWKRecentSearchEntry.h>
#import <WMFModel/MWKRecentSearchList.h>

#import <WMFModel/WMFImageTagParser.h>
#import <WMFModel/WMFImageTag.h>
#import <WMFModel/WMFImageTag+TargetImageWidthURL.h>
#import <WMFModel/WMFImageTagList.h>
#import <WMFModel/WMFImageTagList+ImageURLs.h>

#import <WMFModel/MWKProtectionStatus.h>

#import <WMFModel/MWLanguageInfo.h>

#import <WMFModel/MWKImageInfo.h>
#import <WMFModel/NSString+WMFExtras.h>

#import <WMFModel/SDWebImageManager+WMFCacheRemoval.h>
#import <WMFModel/SDImageCache+WMFPersistentCache.h>
#import <WMFModel/WMFURLCache.h>

#import <WMFModel/MWKArticle+WMFSharing.h>
#import <WMFModel/MWKCitation.h>
#import <WMFModel/MWKHistoryEntry+WMFDatabaseStorable.h>

#import <WMFModel/MWKImage+CanonicalFilenames.h>
#import <WMFModel/MWKImageInfo+MWKImageComparison.h>
#import <WMFModel/MWKList+Subclass.h>
#import <WMFModel/MWKSavedPageEntry+ImageMigration.h>
#import <WMFModel/MWKSavedPageListDataExportConstants.h>
#import <WMFModel/WikipediaAppUtils.h>
#import <WMFModel/NSString+WMFHTMLParsing.h>
#import <WMFModel/WMFImageURLParsing.h>
#import <WMFModel/WMFZeroConfiguration.h>
#import <WMFModel/WMFZeroConfigurationFetcher.h>
#import <WMFModel/MWKSectionMetaData.h>
#import <WMFModel/MWKLanguageLink.h>

#import <WMFModel/MWKLanguageLinkController.h>
#import <WMFModel/MWKLanguageFilter.h>
#import <WMFModel/WMFApiJsonResponseSerializer.h>
#import <WMFModel/MWKLanguageLinkResponseSerializer.h>
#import <WMFModel/WMFMantleJSONResponseSerializer.h>
#import <WMFModel/WMFNetworkUtilities.h>
#import <WMFModel/WMFRelatedSectionBlackList.h>
#import <WMFModel/FetcherBase.h>

#import <WMFModel/UIScreen+WMFImageWidth.h>
#import <WMFModel/NSURL+WMFMainPage.h>
#import <WMFModel/WMFAssetsFile.h>

#import <WMFModel/MWNetworkActivityIndicatorManager.h>

#import <WMFModel/MWKHistoryEntry+WMFDatabaseViews.h>
#import <WMFModel/MWKLanguageLinkController_Private.h>
#import <WMFModel/WMFArticlePreview+WMFDatabaseStorable.h>
#import <WMFModel/WMFArticlePreview.h>
#import <WMFModel/WMFContentGroup.h>
#import <WMFModel/WMFContentGroup+WMFDatabaseViews.h>
#import <WMFModel/WMFContentGroup+WMFDatabaseStorable.h>
#import <WMFModel/WMFDatabaseViewable.h>
#import <WMFModel/WMFFaceDetectionCache.h>
#import <WMFModel/YapDatabase+WMFExtensions.h>
#import <WMFModel/YapDatabaseReadWriteTransaction+WMFCustomNotifications.h>
#import <WMFModel/YapDatabaseViewMappings+WMFMappings.h>
#import <WMFModel/YapDatabaseConnection+WMFExtensions.h>

#import <WMFModel/CIContext+WMFImageProcessing.h>
#import <WMFModel/CIDetector+WMFFaceDetection.h>

#import <WMFModel/WMFContentSource.h>
#import <WMFModel/WMFRelatedPagesContentSource.h>
#import <WMFModel/WMFMainPageContentSource.h>
#import <WMFModel/WMFNearbyContentSource.h>
#import <WMFModel/WMFContinueReadingContentSource.h>
#import <WMFModel/WMFFeedContentSource.h>
#import <WMFModel/WMFRandomContentSource.h>

#import <WMFModel/WMFFeedContentFetcher.h>
#import <WMFModel/WMFFeedDayResponse.h>
#import <WMFModel/WMFFeedTopReadResponse.h>
#import <WMFModel/WMFFeedArticlePreview.h>
#import <WMFModel/WMFFeedImage.h>
#import <WMFModel/WMFFeedNewsStory.h>

#import <WMFModel/MWKSiteInfo.h>
#import <WMFModel/MWKSiteInfoFetcher.h>
#import <WMFModel/WMFRandomArticleFetcher.h>

#import <WMFModel/WMFLocationManager.h>
#import <WMFModel/CLLocationManager+WMFLocationManagers.h>
#import <WMFModel/CLLocation+WMFBearing.h>
#import <WMFModel/NSString+WMFDistance.h>
#import <WMFModel/CLLocation+WMFComparison.h>

#import <WMFModel/WMFRelatedSearchFetcher.h>
#import <WMFModel/WMFRelatedSearchResults.h>
#import <WMFModel/WMFSearchResponseSerializer.h>

#import <WMFModel/MWKLocationSearchResult.h>
#import <WMFModel/WMFLocationSearchResults.h>
#import <WMFModel/WMFLocationSearchFetcher.h>
#import <WMFModel/MWKLocationSearchResult.h>

#import <WMFModel/EventLogger.h>
#import <WMFModel/EventLoggingFunnel.h>
#import <WMFModel/ReadingActionFunnel.h>
#import <WMFModel/AFHTTPSessionManager+WMFConfig.h>
#import <WMFModel/AFHTTPRequestSerializer+WMFRequestHeaders.h>
#import <WMFModel/AFHTTPSessionManager+WMFDesktopRetry.h>
#import <WMFModel/WMFArticlePreviewFetcher.h>
#import <WMFModel/WMFBaseRequestSerializer.h>
#import <WMFModel/MWKSearchResult.h>
#import <WMFModel/NSDictionary+WMFCommonParams.h>

#import <WMFModel/WMFDataSource.h>
#import <WMFModel/WMFDatabaseDataSource.h>
#import <WMFModel/MWKDataStore+WMFDataSources.h>

#import <WMFModel/NSUserActivity+WMFExtensions.h>

#import <WMFModel/PiwikTracker+WMFExtensions.h>


#endif /* WMFModel_global_h */
