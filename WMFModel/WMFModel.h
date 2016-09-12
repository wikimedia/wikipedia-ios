#import <Foundation/Foundation.h>

//! Project version number for WMFModel.
FOUNDATION_EXPORT double WMFModelVersionNumber;

//! Project version string for WMFModel.
FOUNDATION_EXPORT const unsigned char WMFModelVersionString[];

@import WMFUtilities;

#import <WMFModel/MWKDataStore.h>
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

#import <WMFModel/MWKUserDataStore.h>
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
#import <WMFModel/NSDate+WMFMostReadDate.h>
#import <WMFModel/WMFMostReadTitleFetcher.h>
#import <WMFModel/WMFMostReadTitlesResponse.h>

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
