import UIKit

@objc(WMFArticleCollectionViewCell)
public protocol ArticleCollectionViewCell {

    var saveButton: SaveButton! { get }
    
    @objc func configure(article: WMFArticle, contentGroup: WMFContentGroup, layoutOnly: Bool)
}
