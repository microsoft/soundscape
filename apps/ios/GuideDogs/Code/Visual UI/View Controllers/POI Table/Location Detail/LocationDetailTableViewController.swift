//
//  LocationDetailTableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

class LocationDetailTableViewController: UITableViewController {
    
    private enum PrototypeCell: String {
        
        case detail = "CustomDetailCell"
        case annotation = "CustomAnnotationCell"
        
        var identifier: String {
            return self.rawValue
        }
        
    }
    
    // MARK: Properties
    
    private let defaultCell = UITableViewCell(style: .default, reuseIdentifier: "DefaultCell")
    private var userLocation: CLLocation?
    
    var locationDetail: LocationDetail? {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            tableView.reloadData()
        }
    }
    
    private var prototypes: [PrototypeCell] {
        guard let locationDetail = locationDetail else {
            return []
        }
        
        if locationDetail.isMarker || locationDetail.annotation != nil {
            return [.detail, .annotation]
        } else {
            return [.detail]
        }
    }
    
    // MARK: View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.userLocation = AppContext.shared.geolocationManager.location
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        preferredContentSize.height = UIView.preferredContentHeight(for: tableView)
    }
    
    // MARK: `UITableViewDataSource`
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard locationDetail != nil else {
            return 0
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard locationDetail != nil else {
            return 0
        }
        
        return prototypes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            return defaultCell
        }
        
        guard indexPath.row < prototypes.count else {
            return defaultCell
        }
        
        let prototype = prototypes[indexPath.row]
        
        guard let locationDetail = locationDetail else {
            return defaultCell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: prototype.identifier, for: indexPath)
        let labels = locationDetail.labels
        
        switch prototype {
        case .detail:
            guard let cell = cell as? LocationDetailTableViewCell else {
                return defaultCell
            }
            
            // Configure name label
            cell.nameLabel.text = labels.name().text
            cell.nameLabel.accessibilityLabel = labels.name().accessibilityText
            
            // Configure distance label
            let distanceLabel = labels.distance(from: userLocation)
            cell.distanceLabel.text = distanceLabel?.text
            cell.distanceLabel.accessibilityLabel = distanceLabel?.accessibilityText
            
            // Configure address label
            cell.addressLabel.text = labels.address.text
            cell.addressLabel.accessibilityLabel = labels.address.accessibilityText
        case .annotation:
            guard let cell = cell as? LocationDetailAnnotationTableViewCell else {
                return defaultCell
            }
            
            // Configure annotation label
            cell.annotationLabel.text = labels.annotation.text
            cell.annotationLabel.accessibilityLabel = labels.annotation.accessibilityText
        }
        
        // Image view will scale with content size
        cell.imageView?.adjustsImageSizeForAccessibilityContentSizeCategory = true
        
        return cell
    }
    
}
