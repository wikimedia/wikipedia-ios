import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFGrowthTasksDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let csProject = WMFProject.wikipedia(WMFLanguage(languageCode: "cs", languageVariantCode: nil))
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    @Test
    func fetchImageRecommendationCombinedForTasks() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFGrowthTasksDataController(project: csProject)

            let imageRecommendations = try await controller.imageRecommendationsCombined()

            #expect(imageRecommendations.isEmpty == false)
        }
    }

    @Test
    func parseImageRecommendationsCombined() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFGrowthTasksDataController(project: enProject)

            let imageRecommendations = try await controller.imageRecommendationsCombined()
            let firstImageRecommendation = try #require(imageRecommendations.first)

            #expect(firstImageRecommendation.pageid == 6706133)
            #expect(firstImageRecommendation.title == "Juan de Salmerón")
            #expect(firstImageRecommendation.growthimagesuggestiondata?.count == 1)

            let firstImageSuggestionData = try #require(firstImageRecommendation.growthimagesuggestiondata?.first)
            #expect(firstImageSuggestionData.titleText == "Juan de Salmerón")
            #expect(firstImageSuggestionData.titleNamespace == 0)
            #expect(firstImageSuggestionData.images.count == 1)

            let firstImageData = try #require(firstImageSuggestionData.images.first)
            #expect(firstImageData.image == "Juan_de_Salmerón.JPG")
            #expect(firstImageData.displayFilename == "Juan de Salmerón.JPG")
            #expect(firstImageData.source == "wikipedia")
            #expect(firstImageData.projects.count == 1)

            let imageMetadata = firstImageData.metadata
            #expect(imageMetadata.descriptionUrl == "https://commons.wikimedia.org/wiki/File:Juan_de_Salmer%C3%B3n.JPG")
            #expect(imageMetadata.thumbUrl == "//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Juan_de_Salmer%C3%B3n.JPG/120px-Juan_de_Salmer%C3%B3n.JPG")
            #expect(imageMetadata.fullUrl == "//upload.wikimedia.org/wikipedia/commons/d/d0/Juan_de_Salmer%C3%B3n.JPG")
            #expect(imageMetadata.originalWidth == 764)
            #expect(imageMetadata.originalHeight == 1090)
            #expect(imageMetadata.mediaType == "BITMAP")
            #expect(imageMetadata.description == "El Licenciado Juan de Salmerón, fundador de Puebla")
            #expect(imageMetadata.author == "<a href=\"//commons.wikimedia.org/wiki/User:Gusvel\" title=\"User:Gusvel\">Gusvel</a>")
            #expect(imageMetadata.license == "CC BY-SA 4.0")
            #expect(imageMetadata.date == "2010-10-19")
            #expect(imageMetadata.categories.count == 1)
            #expect(imageMetadata.reason == "Used in the same article in Spanish Wikipedia.")
            #expect(imageMetadata.contentLanguageName == "English")
        }
    }

    @Test
    func fetchArticleSummary() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFArticleSummaryDataController.shared

            let articleSummary = try await controller.fetchArticleSummary(project: csProject, title: "Novela (právo)")

            #expect(articleSummary.displayTitle == "<span class=\"mw-page-title-main\">Novela (právo)</span>")
            #expect(articleSummary.description == "změna zákona")
            #expect(articleSummary.extractHtml == "<p><b>Novelou</b> se nazývá takový právní předpis, kterým se mění či doplňuje, cizím slovem <i>novelizuje</i>, jiný právní předpis. Novely jsou vydávány buď jako samostatné právní předpisy nebo jsou připojeny k jiným předpisům zpravidla na jejich konec. Název se odvozuje od výrazu „Novellae“, což je sbírka nařízení císaře Justiniána I. z let 534–569, která byla zařazena do souboru římského práva Corpus iuris civilis jako dodatek. Odlišným od novelizace je výraz „novace“, který má místo v soukromém právu, kde jde o novace závazků.</p>")
        }
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.mediaWikiService = WMFMockGrowthTasksService()
        WMFDataEnvironment.current.basicService = WMFMockBasicService()
    }
}

private extension WMFGrowthTasksDataController {
    func imageRecommendationsCombined() async throws -> [WMFImageRecommendation.Page] {
        try await withCheckedThrowingContinuation { continuation in
            getImageRecommendationsCombined { result in
                continuation.resume(with: result)
            }
        }
    }
}
