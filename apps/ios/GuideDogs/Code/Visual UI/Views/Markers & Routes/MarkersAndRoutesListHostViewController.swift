//
//  MarkersAndRoutesListHostViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

class MarkersAndRoutesListHostViewController: UIHostingController<AnyView> {
    required init?(coder aDecoder: NSCoder) {
        let navHelper = MarkersAndRoutesListNavigationHelper()
        let root = MarkersAndRoutesList()
            .environmentObject(navHelper)
            .environmentObject(UserLocationStore())
            .environment(\.realmConfiguration, RealmHelper.databaseConfig)
        
        super.init(coder: aDecoder, rootView: AnyView(root))
        
        navHelper.host = self
    }
    
    @IBAction func unwindToMarkers(segue: UIStoryboardSegue) {}
    
    var onDismissPreviewHandler: (() -> Void)?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure the back button
        navigationItem.backBarButtonItem = UIBarButtonItem.defaultBackBarButtonItem
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? UINavigationController, let viewController = navigationController.topViewController as? PreviewViewController {
            let locationDetail = sender as? LocationDetail
            viewController.locationDetail = locationDetail
            viewController.onDismissHandler = { [weak self] in
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }
        
        if let viewController = segue.destination as? PreviewViewController {
            let locationDetail = sender as? LocationDetail
            viewController.locationDetail = locationDetail
            viewController.onDismissHandler = onDismissPreviewHandler
        }
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        guard parent == nil else {
            return
        }
        
        // If the user has returned to the Home screen from Saved Markers, remove the
        // isNew flag from all marked points.
        do {
            try SpatialDataCache.clearNewReferenceEntities()
            try SpatialDataCache.clearNewRoutes()
        } catch {
            GDLogAppError("Unable to clear isNew flag for reference entities!")
        }
    }
}
