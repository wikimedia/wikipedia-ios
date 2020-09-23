import Foundation

extension ArticleViewController {
    func getMediaList(_ completion: @escaping (Result<MediaList, Error>) -> Void) {
        assert(Thread.isMainThread)
        if let mediaList = mediaList {
            completion(.success(mediaList))
            return
        }
        
        let request: URLRequest
        do {
            request = try fetcher.mobileHTMLMediaListRequest(articleURL: articleURL)
        } catch (let error) {
            completion(.failure(error))
            return
        }
        
        fetcher.fetchMediaList(with: request) { [weak self] (result, _) in
            DispatchQueue.main.async {
                switch result {
                case .success(let mediaList):
                    self?.mediaList = mediaList
                    completion(.success(mediaList))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func showImage(src: String, href: String, width: Int?, height: Int?) {
        getMediaList { (result) in
            switch result {
            case .failure(let error):
                self.showError(error)
            case .success(let mediaList):
                self.showImage(in: mediaList, src: src, href: href, width: width, height: height)
            }
        }
    }

    func showLeadImage() {
        getMediaList { (result) in
            switch result {
            case .failure(let error):
                self.showError(error)
            case .success(let mediaList):
                self.showImage(in: mediaList, item: nil)
            }
        }
    }
    
    func showImage(in mediaList: MediaList, src: String, href: String, width: Int?, height: Int?) {
        let title = href.replacingOccurrences(of: "./", with: "", options: .anchored)
        guard let index = mediaList.items.firstIndex(where: { $0.title == title }) else {
            showImage(in: mediaList, item: nil)
            return
        }
        let item = mediaList.items[index]
        showImage(in: mediaList, item: item)
    }
    
    func showImage(in mediaList: MediaList, item: MediaListItem?) {
        let gallery = getGalleryViewController(for: item, in: mediaList)
        present(gallery, animated: true)
    }

    func fetchAndDisplayGalleryViewController() {
        /// We can't easily change the photos on the VC after it launches, so we create a loading VC screen and then add the proper galleryVC as a child after the data returns.

        let emptyPhotoViewer = WMFImageGalleryViewController(photos: nil)
        let activityIndicator = UIActivityIndicatorView(style: .white)
        emptyPhotoViewer.view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: emptyPhotoViewer.view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: emptyPhotoViewer.view.centerYAnchor)
        ])
        activityIndicator.startAnimating()
        present(emptyPhotoViewer, animated: true)

        getMediaList { (result) in
            switch result {
            case .failure(let error):
                let completion = {
                    self.showError(error)
                }
                emptyPhotoViewer.dismiss(animated: true, completion: completion)
            case .success(let mediaList):
                activityIndicator.stopAnimating()
                let gallery = self.getGalleryViewController(for: nil, in: mediaList)
                emptyPhotoViewer.wmf_add(childController: gallery, andConstrainToEdgesOfContainerView: emptyPhotoViewer.view)
            }
        }
    }

    func getGalleryViewController(for item: MediaListItem?, in mediaList: MediaList) -> MediaListGalleryViewController {
        return MediaListGalleryViewController(articleURL: articleURL, mediaList: mediaList, dataStore: dataStore, initialItem: item, theme: theme)
    }
}
