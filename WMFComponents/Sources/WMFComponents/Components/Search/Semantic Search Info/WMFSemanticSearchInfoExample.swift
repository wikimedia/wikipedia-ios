import UIKit
import WMFData

/// Real passages kept in the app, so the info sheet shows a result in the search language
/// without a network request. Every example is the Moon article of its wiki, as the search API
/// returned it. The thumbnails are bundled copies of the lead image of each article.
struct WMFSemanticSearchInfoExample {

    let query: String
    let project: WMFProject
    let result: WMFSemanticSearchResult
    let thumbnail: UIImage?
    let attribution: WMFSemanticSearchAttribution

    private static let moonThumbnail = UIImage(named: "semantic-search-example-moon", in: .module, with: nil)
    private static let japaneseMoonThumbnail = UIImage(named: "semantic-search-example-moon-ja", in: .module, with: nil)

    static func forLanguage(_ languageCode: String?) -> WMFSemanticSearchInfoExample {
        switch languageCode {
        case "ar":
            return arabic
        case "fr":
            return french
        case "ja":
            return japanese
        default:
            return english
        }
    }

    private static func wikipedia(_ languageCode: String) -> WMFProject {
        .wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: nil))
    }

    private static let english = WMFSemanticSearchInfoExample(
        query: "How was the moon formed?",
        project: wikipedia("en"),
        result: WMFSemanticSearchResult(
            pageID: 19331,
            title: "Moon",
            snippetHTML: "The prevailing theory is that the Earth–Moon system formed after a giant impact of a Mars -sized body (named Theia) with the proto-Earth. <span class=\"searchmatch\">The oblique impact blasted material into orbit about the Earth</span> and the material accreted and formed the Moon just beyond the Earth&#039;s Roche limit of ~ 2.56 R.",
            sectionTitle: "Formation",
            redirectTitle: nil,
            thumbnailURL: nil
        ),
        thumbnail: moonThumbnail,
        attribution: WMFSemanticSearchAttribution(contributorCount: 2751, referenceCount: 464, lastUpdated: nil)
    )

    private static let arabic = WMFSemanticSearchInfoExample(
        query: "كيف تشكّل القمر؟",
        project: wikipedia("ar"),
        result: WMFSemanticSearchResult(
            pageID: 1619,
            title: "القمر",
            snippetHTML: "اقترحت عدة نظريات لتفسير تشكل القمر قبل 4.527 ± 0.010 مليار سنة، إحدى الفرضيات تفرض بأن القمر انشطر من القشرة الأرضية بسبب القوة الطاردة المركزية ، خلال فترة امتدت بين 30 و50 مليون سنة من تشكل المجموعة الشمسية ، والذي يتطلب دورانا ذاتيا ، كبيرا للأرض وقد نجحت الجاذبية في وضع القمر المتشكل في مسار حولها والذي سيتطلب بدوره توسعا كبيرا للغلاف الجوي الأرضي لتبديد الطاقة الناتجة عن ابتعاد القمر ومرروه، ليعاد تشكيل القمر والأرض ضمن القرص المزود الأساسي. وهذا لا يستطيع تفسير استنزاف الحديد من القمر. كما لا تستطيع هذه الفرضية تفسير الزخم الزاوي الكبير لنظام الأرض-قمر.",
            sectionTitle: "نشوء القمر",
            redirectTitle: nil,
            thumbnailURL: nil
        ),
        thumbnail: moonThumbnail,
        attribution: WMFSemanticSearchAttribution(contributorCount: 243, referenceCount: nil, lastUpdated: Date(timeIntervalSince1970: 1_790_329_445))
    )

    private static let french = WMFSemanticSearchInfoExample(
        query: "Comment la lune s'est formée\u{00A0}?",
        project: wikipedia("fr"),
        result: WMFSemanticSearchResult(
            pageID: 1893,
            title: "Lune",
            snippetHTML: "<span class=\"searchmatch\">La Lune commence à se former il y a 4,51 milliards d&#039;années</span>, de 30 à 60 millions d&#039;années après la formation du Système solaire,. Plusieurs mécanismes de formation sont proposés, parmi lesquels la séparation de la Lune à partir de la croûte terrestre par la force centrifuge (ce qui exigerait une vitesse de rotation initiale de la Terre trop élevée),, la capture gravitationnelle d&#039;une Lune préformée (ce qui nécessiterait cependant une atmosphère terrestre étendue irréaliste pour dissiper l&#039;énergie de la Lune de passage), et la co-formation de la Terre et de la Lune dans le disque d&#039;accrétion primordial (ce qui ne peut pas expliquer la disparition des métaux dans la Lune),,. Ces hypothèses ne peuvent pas non plus expliquer le moment cinétique élevé du système Terre-Lune.",
            sectionTitle: "Formation",
            redirectTitle: nil,
            thumbnailURL: nil
        ),
        thumbnail: moonThumbnail,
        attribution: WMFSemanticSearchAttribution(contributorCount: 947, referenceCount: 473, lastUpdated: nil)
    )

    private static let japanese = WMFSemanticSearchInfoExample(
        query: "月はどのように形成されたのか？",
        project: wikipedia("ja"),
        result: WMFSemanticSearchResult(
            pageID: 2020012,
            title: "月",
            snippetHTML: "だが、いずれの説も現在の月の力学的・物質科学的な特徴を矛盾なく説明することができなかった。まず、親子説では地球-月系の現在の全 角運動量 を原始地球が単独で持っていたとは考えにくい。兄弟説では月の平均密度から推定される全体的な組成が、地球と比較して金属鉄に乏しいことを説明できない。また、他人説では地球の重力圏外から進入する月が、地球からちょうど良い距離に接近して衛星軌道へ捕らえられる可能性が低い。また、 アポロ計画 により採取された 月の石 の分析結果から判明した地球の マントル と月の石の化学組成や 酸素同位体 比の類似性も、他人説は説明できない。一方で、 月の石 の 放射年代測定 により月が<span class=\"searchmatch\">約45億5000万年前に</span>誕生したこと、月の高地が斜長岩からなることから月はその歴史の初期に高温だったことが明らかとなった。これらの証拠から、有力視されるようになったのが巨大衝突説である。",
            sectionTitle: "古典的学説",
            redirectTitle: nil,
            thumbnailURL: nil
        ),
        thumbnail: japaneseMoonThumbnail,
        attribution: WMFSemanticSearchAttribution(contributorCount: nil, referenceCount: 71, lastUpdated: Date(timeIntervalSince1970: 1_790_592_983))
    )
}
