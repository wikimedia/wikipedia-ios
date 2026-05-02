import Foundation

/// A display model representing a country pin on the trending map.
public struct WMFTrendingCountryAnnotation: Identifiable, Sendable {
    public let id: String           // ISO 3166-1 alpha-2 country code
    public let name: String
    public let languageCode: String
    public let latitude: Double
    public let longitude: Double

    public static let all: [WMFTrendingCountryAnnotation] = [
        .init(id: "US", name: "United States",    languageCode: "en", latitude:  37.09, longitude:  -95.71),
        .init(id: "GB", name: "United Kingdom",   languageCode: "en", latitude:  55.38, longitude:   -3.44),
        .init(id: "CA", name: "Canada",           languageCode: "en", latitude:  56.13, longitude: -106.35),
        .init(id: "AU", name: "Australia",        languageCode: "en", latitude: -25.27, longitude:  133.78),
        .init(id: "DE", name: "Germany",          languageCode: "de", latitude:  51.17, longitude:   10.45),
        .init(id: "AT", name: "Austria",          languageCode: "de", latitude:  47.52, longitude:   14.55),
        .init(id: "FR", name: "France",           languageCode: "fr", latitude:  46.23, longitude:    2.21),
        .init(id: "BE", name: "Belgium",          languageCode: "fr", latitude:  50.50, longitude:    4.47),
        .init(id: "CH", name: "Switzerland",      languageCode: "fr", latitude:  46.82, longitude:    8.23),
        .init(id: "ES", name: "Spain",            languageCode: "es", latitude:  40.46, longitude:   -3.75),
        .init(id: "MX", name: "Mexico",           languageCode: "es", latitude:  23.63, longitude: -102.55),
        .init(id: "AR", name: "Argentina",        languageCode: "es", latitude: -38.42, longitude:  -63.62),
        .init(id: "CO", name: "Colombia",         languageCode: "es", latitude:   4.57, longitude:  -74.30),
        .init(id: "CL", name: "Chile",            languageCode: "es", latitude: -35.68, longitude:  -71.54),
        .init(id: "BR", name: "Brazil",           languageCode: "pt", latitude: -14.24, longitude:  -51.93),
        .init(id: "PT", name: "Portugal",         languageCode: "pt", latitude:  39.40, longitude:   -8.22),
        .init(id: "IT", name: "Italy",            languageCode: "it", latitude:  41.87, longitude:   12.57),
        .init(id: "NL", name: "Netherlands",      languageCode: "nl", latitude:  52.13, longitude:    5.29),
        .init(id: "PL", name: "Poland",           languageCode: "pl", latitude:  51.92, longitude:   19.15),
        .init(id: "SE", name: "Sweden",           languageCode: "sv", latitude:  60.13, longitude:   18.64),
        .init(id: "NO", name: "Norway",           languageCode: "no", latitude:  60.47, longitude:    8.47),
        .init(id: "DK", name: "Denmark",          languageCode: "da", latitude:  56.26, longitude:    9.50),
        .init(id: "FI", name: "Finland",          languageCode: "fi", latitude:  61.92, longitude:   25.75),
        .init(id: "RU", name: "Russia",           languageCode: "ru", latitude:  61.52, longitude:  105.32),
        .init(id: "UA", name: "Ukraine",          languageCode: "uk", latitude:  48.38, longitude:   31.17),
        .init(id: "GR", name: "Greece",           languageCode: "el", latitude:  39.07, longitude:   21.82),
        .init(id: "CZ", name: "Czech Republic",   languageCode: "cs", latitude:  49.82, longitude:   15.47),
        .init(id: "HU", name: "Hungary",          languageCode: "hu", latitude:  47.16, longitude:   19.50),
        .init(id: "RO", name: "Romania",          languageCode: "ro", latitude:  45.94, longitude:   24.97),
        .init(id: "TR", name: "Turkey",           languageCode: "tr", latitude:  38.96, longitude:   35.24),
        .init(id: "IL", name: "Israel",           languageCode: "he", latitude:  31.05, longitude:   34.85),
        .init(id: "SA", name: "Saudi Arabia",     languageCode: "ar", latitude:  23.89, longitude:   45.08),
        .init(id: "EG", name: "Egypt",            languageCode: "ar", latitude:  26.82, longitude:   30.80),
        .init(id: "AE", name: "UAE",              languageCode: "ar", latitude:  23.42, longitude:   53.85),
        .init(id: "IN", name: "India",            languageCode: "hi", latitude:  20.59, longitude:   78.96),
        .init(id: "PK", name: "Pakistan",         languageCode: "en", latitude:  30.38, longitude:   69.35),
        .init(id: "ID", name: "Indonesia",        languageCode: "id", latitude:  -0.79, longitude:  113.92),
        .init(id: "TH", name: "Thailand",         languageCode: "th", latitude:  15.87, longitude:  100.99),
        .init(id: "VN", name: "Vietnam",          languageCode: "vi", latitude:  14.06, longitude:  108.28),
        .init(id: "JP", name: "Japan",            languageCode: "ja", latitude:  36.20, longitude:  138.25),
        .init(id: "KR", name: "South Korea",      languageCode: "ko", latitude:  35.91, longitude:  127.77),
        .init(id: "CN", name: "China",            languageCode: "zh", latitude:  35.86, longitude:  104.19),
        .init(id: "NG", name: "Nigeria",          languageCode: "en", latitude:   9.08, longitude:    8.68),
        .init(id: "ZA", name: "South Africa",     languageCode: "en", latitude: -30.56, longitude:   22.94)
    ]
}
