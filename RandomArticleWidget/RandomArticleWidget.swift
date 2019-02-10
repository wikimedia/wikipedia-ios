//
//  RandomArticleWidget.swift
//  RandomArticleWidget
//
//  Created by David Lynch on 2/5/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import UIKit
import NotificationCenter
import WMF

class RandomArticleWidget: UIViewController, NCWidgetProviding {
    let randomArticleFetcher = RandomArticleFetcher()
    let articlePreviewFetcher = WMFArticlePreviewFetcher()
    let collapsedArticleView = ArticleRightAlignedImageCollectionViewCell()
    let expandedArticleView = ArticleFullWidthImageCollectionViewCell()

    var isExpanded = true
    
    var isEmptyViewHidden = true {
        didSet {
            collapsedArticleView.isHidden = !isEmptyViewHidden
            expandedArticleView.isHidden = !isEmptyViewHidden
        }
    }
    
    var article: WMFArticle?
//    var currentArticleKey: String?
    
    var dataStore: MWKDataStore? {
        return SessionSingleton.sharedInstance()?.dataStore
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGR)
        
        collapsedArticleView.frame = view.bounds
        view.addSubview(collapsedArticleView)
        
        expandedArticleView.saveButton.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        expandedArticleView.frame = view.bounds
        view.addSubview(expandedArticleView)
        
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        defer {
            updateView()
        }
        
        let siteURL = SessionSingleton.sharedInstance().currentArticleSiteURL
        self.randomArticleFetcher.fetchRandomArticle(withSiteURL: siteURL!, completion: { (error, result, summary) in
            if (error != nil) {
                completionHandler(.failed)
                return
            }
            
            self.articlePreviewFetcher.fetchArticlePreviewResults(forArticleURLs: [result!], siteURL: siteURL!, completion: { (searchResults) in
                DispatchQueue.main.async {
                    guard let article = self.dataStore?.viewContext.fetchOrCreateArticle(with: result, updatedWith: searchResults[0]) else {
                        assertionFailure("Coudn't fetch an article with \(String(describing: result))")
                        completionHandler(.failed)
                        return
                    }
                    
                    // print("article", article)
                    self.article = article
                    
                    let theme:Theme = .widget
                    
                    self.collapsedArticleView.configure(article: article, displayType: .relatedPages, index: 0, shouldShowSeparators: false, theme: theme, layoutOnly: false)
                    self.collapsedArticleView.titleTextStyle = .body
                    self.collapsedArticleView.updateFonts(with: self.traitCollection)
                    self.collapsedArticleView.tintColor = theme.colors.link
                    
                    self.expandedArticleView.configure(article: article, displayType: .pageWithPreview, index: 0, theme: theme, layoutOnly: false)
                    self.expandedArticleView.tintColor = theme.colors.link
                    self.expandedArticleView.saveButton.saveButtonState = article.savedDate == nil ? .longSave : .longSaved
                    
                    completionHandler(.newData)
                }
            }, failure: { (error) in
                // print("couldn't fetch preview")
                completionHandler(.failed)
            })
        })
    }
    
    func updateViewAlpha(isExpanded: Bool) {
        expandedArticleView.alpha = isExpanded ? 1 : 0
        collapsedArticleView.alpha =  isExpanded ? 0 : 1
    }
    
    @objc func updateView() {
        guard viewIfLoaded != nil else {
            return
        }
        var maximumSize = CGSize(width: view.bounds.size.width, height: UIView.noIntrinsicMetric)
        if let context = extensionContext {
            isExpanded = context.widgetActiveDisplayMode == .expanded
            maximumSize = context.widgetMaximumSize(for: context.widgetActiveDisplayMode)
        }
        updateViewAlpha(isExpanded: isExpanded)
        updateViewWithMaximumSize(maximumSize, isExpanded: isExpanded)
    }
    
    func updateViewWithMaximumSize(_ maximumSize: CGSize, isExpanded: Bool) {
        let sizeThatFits: CGSize
        if isExpanded {
            sizeThatFits = expandedArticleView.sizeThatFits(CGSize(width: maximumSize.width, height:UIView.noIntrinsicMetric), apply: true)
            expandedArticleView.frame = CGRect(origin: .zero, size:sizeThatFits)
        } else {
            collapsedArticleView.imageViewDimension = maximumSize.height - 30 //hax
            sizeThatFits = collapsedArticleView.sizeThatFits(CGSize(width: maximumSize.width, height:UIView.noIntrinsicMetric), apply: true)
            collapsedArticleView.frame = CGRect(origin: .zero, size:sizeThatFits)
        }
        preferredContentSize = CGSize(width: maximumSize.width, height: sizeThatFits.height)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        debounceViewUpdate()
    }
    
    func debounceViewUpdate() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateView), object: nil)
        perform(#selector(updateView), with: nil, afterDelay: 0.1)
    }
    
    @objc func saveButtonPressed() {
        guard let article = self.article, let articleKey = article.key else {
            return
        }
        let isSaved = dataStore?.savedPageList.toggleSavedPage(forKey: articleKey) ?? false
        expandedArticleView.saveButton.saveButtonState = isSaved ? .longSaved : .longSave
    }
    
    @objc func handleTapGesture(_ tapGR: UITapGestureRecognizer) {
        guard tapGR.state == .recognized else {
            return
        }
        guard let article = self.article, let articleURL = article.url else {
            return
        }
        
        let URL = articleURL as NSURL?
        let URLToOpen = URL?.wmf_wikipediaScheme ?? NSUserActivity.wmf_baseURLForActivity(of: .explore)
        
        self.extensionContext?.open(URLToOpen)
    }
}
