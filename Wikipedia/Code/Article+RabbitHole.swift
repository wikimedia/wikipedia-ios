import Foundation
import UIKit

extension ArticleViewController {
    struct RabbitHoleData {
        let title: String
        let leadImageUrlString: String?
    }

    @objc private func rabbitHoleShare() {
        if (false) {
            let activityVC = UIActivityViewController(activityItems: [rabbitHoleImage as Any], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = view
            activityVC.popoverPresentationController?.permittedArrowDirections = .up
            self.present(activityVC, animated: true, completion: nil)
        } else {
            let vc = UIViewController()
            guard let rabbitHoleView = rabbitHoleView else {
                assertionFailure("No rabbit hole view")
                return
            }
//            let rabbitHoleImageView = UIImageView(image: rabbitHoleImage)
//            rabbitHoleImageView.contentMode = .topLeft
            vc.view.addSubview(rabbitHoleView)
            rabbitHoleView.translatesAutoresizingMaskIntoConstraints = false
            rabbitHoleView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor).isActive = true
            rabbitHoleView.topAnchor.constraint(equalTo: vc.view.topAnchor).isActive = true
            self.present(vc, animated: true, completion: nil)
        }
    }

    private func setRabbitHoleStack() {
        if let nc = self.navigationController,
           // Pull Prior VC. If it's not an ArticleVC, then start a fresh stack. (Could be a SearchVC for instance.)
           let priorVC = (nc.children.last(where: {$0 != self}) as? ArticleViewController),
           let thisTitle = articleURL.wmf_title {
            articleRabbitHole = priorVC.articleRabbitHole
            let dataForVC = RabbitHoleData(title: thisTitle, leadImageUrlString: article.imageURLString)
            articleRabbitHole?.insert(dataForVC, at: 0)
        } else {

            // CAN REMOVE SOEM OF THIS UNLESS NEED IT WHEN RECONSITUTITNG

            /// Because `pruneSearchControllers` runs when we move backwards (potentially removing searches, we set this when we load the screen.
            guard let stopVCIndex = navigationController?.viewControllers.lastIndex(where: { !($0 is ArticleViewController) }), let stopVC = navigationController?.viewControllers[stopVCIndex] else {
                assertionFailure("couldn't find a stopVC")
                return
            }

            articleRabbitHole = navigationController?.viewControllers[(stopVCIndex+1)...].compactMap({
                guard let articleTitle = ($0 as? ArticleViewController)?.articleURL.wmf_title else {
                    assertionFailure("No title found to save")
                    return nil
                }
                let articleURL = ($0 as? ArticleViewController)?.article.imageURLString
                return RabbitHoleData(title: articleTitle, leadImageUrlString: articleURL)
            }).reversed()

            if stopVC is SearchViewController {//, let searchTerm = searchVC.searchTerm {
                articleRabbitHole?.append(RabbitHoleData(title: CommonStrings.searchTitle, leadImageUrlString: nil))
            } else if let baseItemTitle: String = stopVC.navigationItem.backButtonTitle {
                articleRabbitHole?.append(RabbitHoleData(title: baseItemTitle, leadImageUrlString: nil))
            }
        }
    }

    private var rabbitHoleView: UIView? {
        let overallView = UIView()
        overallView.backgroundColor = .lightGray

        guard let articleLabels: [UIView] = articleRabbitHole?.map( {
            return getRabbitHoleChip(for: $0.title, with: $0.leadImageUrlString)
        } ) else {
            return nil
        }

        let stackView = UIStackView(arrangedSubviews: articleLabels)
        stackView.axis = .vertical

        overallView.wmf_addSubview(stackView, withConstraintsToEdgesWithInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        overallView.translatesAutoresizingMaskIntoConstraints = false
        overallView.layoutIfNeeded()
        return overallView
    }

    private var rabbitHoleImage: UIImage? {
        return rabbitHoleView?.asImage
    }

    private func getRabbitHoleChip(for title: String, with imageURLString: String?) -> UIView {
        let imageHeight: CGFloat = 30.0
        let leadImageView = UIImageView()
        leadImageView.cornerRadius = imageHeight/2
        leadImageView.masksToBounds = true
        leadImageView.contentMode = .scaleAspectFill

        if let imageURLString = imageURLString, let imageURL = URL(string: imageURLString) {
            leadImageView.wmf_setImage(with: imageURL, detectFaces: false, onGPU: false, failure: {_ in }, success: {})
        } else if let matchingTabBarImage = self.navigationController?.children.first(where: {$0 is WMFAppViewController})?.children.first(where: {$0.title == title})?.tabBarItem.image {
            // This also captures "Search", whether it comes via the tab bar or an article VC.
            // This above line is very very ugly, apologies. That said, I don't believe it's a fragile as it looks.
            leadImageView.image = matchingTabBarImage

            // Don't want to clip our icons, but had a bug and was showing as too big. Thus, aspectFit
            leadImageView.masksToBounds = false
            leadImageView.contentMode = .scaleAspectFit
        } else {
            leadImageView.backgroundColor = .darkGray
        }

        let label = UILabel()
        label.text = title

        let enclosingView = UIView()
        [leadImageView, label].forEach({
            enclosingView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.topAnchor.constraint(equalTo: enclosingView.topAnchor).isActive = true
        })

        NSLayoutConstraint.activate([
            leadImageView.heightAnchor.constraint(equalToConstant: imageHeight),
            leadImageView.widthAnchor.constraint(equalToConstant: imageHeight),
            leadImageView.leadingAnchor.constraint(equalTo: enclosingView.leadingAnchor),
            label.leadingAnchor.constraint(equalTo: leadImageView.trailingAnchor, constant: 10),
            enclosingView.trailingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor)
        ])

        let isRootNode = (imageURLString == nil)

        if !isRootNode {
            let arrowImageView = UIImageView(image: #imageLiteral(resourceName: "moveArrowUp").withRenderingMode(.alwaysTemplate))
            arrowImageView.tintColor = .base10
            arrowImageView.contentMode = .scaleAspectFit
            enclosingView.addSubview(arrowImageView)
            arrowImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                leadImageView.bottomAnchor.constraint(equalTo: arrowImageView.topAnchor, constant: -10),
                label.bottomAnchor.constraint(equalTo: arrowImageView.topAnchor, constant: -10),
                arrowImageView.centerXAnchor.constraint(equalTo: enclosingView.centerXAnchor),
                arrowImageView.bottomAnchor.constraint(equalTo: enclosingView.bottomAnchor, constant: -10),
                arrowImageView.widthAnchor.constraint(equalToConstant: imageHeight/2),
                arrowImageView.heightAnchor.constraint(equalToConstant: imageHeight/2)
            ])
        } else {
            leadImageView.bottomAnchor.constraint(equalTo: enclosingView.bottomAnchor).isActive = true
            label.bottomAnchor.constraint(equalTo: enclosingView.bottomAnchor).isActive = true
        }

        return enclosingView
    }
}
