//
//#import <XCTest/XCTest.h>
//#import "SavedArticlesFetcherTests.h"
//#import "SavedArticlesFetcher_Testing.h"
//#import "WMFArticleFetcher.h"
//#import "MWKSavedPageList.h"
//#import "MWKSavedPageEntry.h"
//
//// Test Utils
//#import "WMFAsyncTestCase.h"
//#import "WMFTestFixtureUtilities.h"
//#import "XCTestCase+PromiseKit.h"
//#import "MWKDataStore+TemporaryDataStore.h"
//#import "Wikipedia-Swift.h"
//#import "MWKImageInfoFetcher.h"
//#import "MWKImage+CanonicalFilenames.h"
//
//#define HC_SHORTHAND 1
//#import <OCHamcrest/OCHamcrest.h>
//
//#define MOCKITO_SHORTHAND 1
//#import <OCMockito/OCMockito.h>
//
//typedef void (^ SavedArticlesFetcherDidFetchArticleBlock)(MWKArticle*, CGFloat, NSError*);
//
///**
// *  Verify the proper download & error handling of the SavedArticlesFetcher.
// *
// *  @note @c WMFArticleFetcher is responsible for both fetching <b>and</b> persisting articles. We are mocking it
// *        here for simplicity, but felt it was worth noting that we are not checking the data store here since we
// *        take for granted that the successful resolution of a promise from @c WMFArticleFetcher means the article was
// *        written successfully to disk.
// *
// *  @warning This class is not intended to be subclassed or reused in other tests. The header was only created to
// *           reduce noise in the implementation while providing documentation for utilities needed to make tests readable.
// */
//@interface SavedArticlesFetcherTests : XCTestCase
//    <SavedArticlesFetcherDelegate>
//
///// Test Subject
//@property (nonatomic, strong) SavedArticlesFetcher* savedArticlesFetcher;
//
///// Mock fetcher used feed certain responses to the test subject in order to validate specific behaviors.
//@property (nonatomic, strong) WMFArticleFetcher* mockArticleFetcher;
//
///// Mock image controller
//@property (nonatomic, strong) WMFImageController* mockImageController;
//
//@property (nonatomic, strong) MWKImageInfoFetcher* mockImageInfoFetcher;
//
///// Temporary data store used to validate the test subject's behavior for articles which are or aren't cached.
//@property (nonatomic, strong) MWKDataStore* tempDataStore;
//
///// The saved page list given to the test subject. Mutated during tests to validate the subject's reactions.
//@property (nonatomic, strong) MWKSavedPageList* savedPageList;
//
//
/////
///// @name Test Utilities
/////
//
///**
// *  Tracks the successful downloads in order to verify that the expected articles were downloaded correctly with the
// *  correct progress value.
// */
//@property (nonatomic, strong) NSMutableArray<MWKArticle*>* downloadedArticles;
//
///**
// *  Tracks all download errors retrieved by the delegate.
// */
//@property (nonatomic, strong) NSMutableDictionary<MWKTitle*, NSError*>* downloadErrors;
//
///**
// *  Create an expectation for a <code>-[SavedArticlesFetcherDelegate fetchFinished:fetchedData:status:error:]</code> callback.
// *
// *  @param error Optional. If @c nil, validates that the fetch was successful, otherwise checks to see if the expected
// *               error was passed to the delegate.
// */
//- (void)expectFetcherToFinishWithError:(NSError*)error;
//
///**
// *  Block which checks the @c fetchFinished: callback for the value passed to @c expectFetcherToFinishWithError: method.
// */
//@property (nonatomic, strong) void (^ expectedFetchFinishedError)(NSError*);
//
//@end