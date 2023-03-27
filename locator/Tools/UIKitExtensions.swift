import Foundation
import UIKit

extension UIImage {
    
    /// Retry style sfSymbol image
    static var sfRetry: UIImage {
        let config = UIImage.SymbolConfiguration(textStyle: .caption1)
        let image = UIImage(systemName: "goforward", withConfiguration: config)!
        return image
    }
    
    /// Location style sfSymbol image
    static var sfLocation: UIImage {
        let config = UIImage.SymbolConfiguration(textStyle: .caption1)
        let image = UIImage(systemName: "location", withConfiguration: config)!
        return image
    }
}

extension UICollectionViewLayout {
    
    /// Table like layout with titles for each section
    static var cardsWithSectionTitles: UICollectionViewLayout {
        let sectionProvider = { (sectionIndex: Int,
                                 layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let estimatedSize = UIScreen.main.bounds.width
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(estimatedSize))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: .zero, leading: .margin4, bottom: .zero, trailing: .margin4)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(estimatedSize))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                repeatingSubitem: item,
                count: 1
            )
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = .margin4
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            header.contentInsets = NSDirectionalEdgeInsets(top: .zero, leading: .zero, bottom: .margin4, trailing: .zero)
            section.boundarySupplementaryItems = [header]
            
            return section
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = .margin4

        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: sectionProvider, configuration: config)
        return layout
    }
}
