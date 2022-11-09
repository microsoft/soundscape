//
//  NearbyFilterTableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import DZNEmptyDataSet
import Combine

class NearbyFilterTableViewController: UITableViewController, POITableViewController {
    
    // MARK: `IBOutlet`
    
    @IBOutlet weak var largeBannerContainerView: UIView!
    
    // MARK: Properties
    
    weak var delegate: POITableViewDelegate?
    private var context = NearbyDataContext()
    private var data: NearbyData?
    private var subscriber: AnyCancellable?
    var onDismissPreviewHandler: (() -> Void)?
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the back button
        navigationItem.backBarButtonItem = UIBarButtonItem.defaultBackBarButtonItem
        
        // Save initial value
        data = context.data.value
        
        // Set the DZNEmptyDataSet connections
        tableView.emptyDataSetSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView(title ?? "Explore Nearby", with: ["context": delegate?.usageLog ?? ""])
        
        if let delegate = delegate, delegate.doneNavigationItem {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: GDLocalizedString("general.alert.done"), style: .done, target: self, action: #selector(self.onDone))
        }
        
        subscriber = context.data
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .failure: break // If appropriate, show an alert
                case .finished: break // no-op
                }
            }, receiveValue: { [weak self] (newValue) in
                guard let `self` = self else {
                    return
                }
                
                // Save new value and present
                self.data = newValue
                self.tableView.reloadData()
            })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        subscriber?.cancel()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? POITableViewController {
            viewController.delegate = self.delegate
            viewController.onDismissPreviewHandler = onDismissPreviewHandler
        }
        
        if let viewController = segue.destination as? NearbyTableViewController {
            guard let cell = sender as? UITableViewCell else {
                return
            }
            
            guard let localizedText = cell.textLabel?.text else {
                return
            }
            
            guard let filter = data?.filters.first(where: { $0.localizedString == localizedText }) else {
                return
            }
            
            viewController.context = context
            viewController.currentFilter = filter
        }
    }
    
    @objc
    private func onDone() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: `UITableViewDataSource`
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 0 else {
            return 0
        }
        
        guard let data = data else {
            return 0
        }
        
        return data.filters.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTableViewCell", for: indexPath)
        
        guard let data = data else {
            return cell
        }
        
        guard indexPath.row < data.filters.count else {
            return cell
        }
        
        let filter = data.filters[indexPath.row]
        
        // Configure cell
        cell.textLabel?.text = filter.localizedString
        cell.imageView?.image = filter.image
        
        return cell
    }
    
}

extension NearbyFilterTableViewController: DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let title: String
            
        if context.location == nil {
            // When the location is unknown, the nearby places list will be empty
            title = GDLocalizedString("poi_screen.loading_title.finding_error")
        } else {
            // Fetching nearby places
            title = GDLocalizedString("poi_screen.loading_title.loading")
        }
        
        let color = Colors.Foreground.primary ?? .white
        let attributes = [
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title1),
            NSAttributedString.Key.foregroundColor: color
        ]
        
        return NSAttributedString(string: title, attributes: attributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "ic__pin_drop_32px")
    }
    
}

extension NearbyFilterTableViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
}

extension NearbyFilterTableViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerView.setHeight(height)
        tableView.reloadData()
    }
    
}
