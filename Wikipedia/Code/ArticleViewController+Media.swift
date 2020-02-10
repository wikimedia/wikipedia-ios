import Foundation

extension ArticleViewController {
    func getMediaList(_ completion: @escaping (Result<MediaList, Error>) -> Void) {
        assert(Thread.isMainThread)
        if let mediaList = mediaList {
            completion(.success(mediaList))
        }
        fetcher.fetchMediaList(with: articleURL) { [weak self] (result, _) in
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
        let gallery = MediaListGalleryViewController(articleURL: articleURL, mediaList: mediaList, initialItem: item, theme: theme)
        present(gallery, animated: true)
    }
}
