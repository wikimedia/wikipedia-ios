import Foundation

/// Provides hardcoded cat image URLs based on reading streak level
public struct WMFCatStreakImageURLs {
    
    /// Returns a cat image URL for the given streak count
    /// - Parameter streak: The reading streak count (0-7)
    /// - Returns: A URL for the cat image, or nil if invalid streak
    public static func getCatImageURL(for streak: Int) -> URL? {
        let urlString: String
        
        switch streak {
        case 0:
            // No streak - sleepy cat
            urlString = "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Felis_catus-cat_on_snow.jpg/440px-Felis_catus-cat_on_snow.jpg"
        case 1:
            // Day 1 - curious cat
            urlString = "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Cat03.jpg/440px-Cat03.jpg"
        case 2:
            // Day 2 - attentive cat
            urlString = "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Cat_November_2010-1a.jpg/440px-Cat_November_2010-1a.jpg"
        case 3:
            // Day 3 - playful cat
            urlString = "https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/Orange_tabby_cat_sitting_on_fallen_leaves-Hisashi-01A.jpg/440px-Orange_tabby_cat_sitting_on_fallen_leaves-Hisashi-01A.jpg"
        case 4:
            // Day 4 - focused cat
            urlString = "https://upload.wikimedia.org/wikipedia/commons/thumb/b/bb/Kittyply_edit1.jpg/440px-Kittyply_edit1.jpg"
        case 5:
            // Day 5 - confident cat
            urlString = "https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Cat_August_2010-4.jpg/440px-Cat_August_2010-4.jpg"
        case 6:
            // Day 6 - majestic cat
            urlString = "https://upload.wikimedia.org/wikipedia/commons/thumb/6/64/Collage_of_Six_Cats-02.jpg/440px-Collage_of_Six_Cats-02.jpg"
        case 7...Int.max:
            // Day 7+ - champion cat
            urlString = "https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Lynx_Chaton.jpg/440px-Lynx_Chaton.jpg"
        default:
            return nil
        }
        
        return URL(string: urlString)
    }
    
    /// All cat image URLs for streak levels 0 through 7
    public static var allCatImageURLs: [URL] {
        return (0...7).compactMap { getCatImageURL(for: $0) }
    }
}
