class PlaceSearchFilterListController: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        configureCell(cell: cell, forRowAt: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let myCell = cell as? PlaceSearchFilterCell else {
            return
        }
        
        if (indexPath.row == 0) {
            myCell.titleLabel.text = localizedStringForKeyFallingBackOnEnglish("places-filter-top-articles")
            myCell.subtitleLabel.text = localizedStringForKeyFallingBackOnEnglish("places-filter-top-articles-count").replacingOccurrences(of: "$1", with: "0")
            
   
        } else if (indexPath.row == 1) {
            myCell.titleLabel.text = localizedStringForKeyFallingBackOnEnglish("places-filter-saved-articles")
            myCell.subtitleLabel.text = localizedStringForKeyFallingBackOnEnglish("places-filter-saved-articles-count").replacingOccurrences(of: "$1", with: "0")
        }
    }
    
    //MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
