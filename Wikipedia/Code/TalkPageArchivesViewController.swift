import UIKit

class TalkPageArchivesViewController: CustomNavigationViewController {
    
    var items: [String] = []
    
    var archivesView: TalkPageArchivesViewUIKit {
        return view as! TalkPageArchivesViewUIKit
    }
    
    override func loadView() {
        let archivesView = TalkPageArchivesViewUIKit(frame: UIScreen.main.bounds)
        _scrollView = archivesView.tableView
        view = archivesView
    }
    
    let redView = TempShiftingView(color: .red, order: 2)
    let blueView = TempShiftingView(color: .blue, order: 1)
    let greenView = TempShiftingView(color: .green, order: 0)
    let navBar = ShiftingNavigationBarView(order: 2)
    
    override var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] {
        return [navBar, blueView, greenView]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        archivesView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "basicStyle")
        archivesView.tableView.dataSource = self
        archivesView.tableView.delegate = self
        
        for _ in 0..<100 {
            items.append("Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.")
        }
        
        archivesView.tableView.reloadData()
    }
}

extension TalkPageArchivesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicStyle", for: indexPath)
        cell.textLabel!.text = items[indexPath.row]
        return cell
    }
}

extension TalkPageArchivesViewController: UITableViewDelegate {
    
}
