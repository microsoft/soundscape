//
//  MarkersAndRoutesListNavigationHelper.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

class MarkersAndRoutesListNavigationHelper: ViewNavigationHelper, LocationAccessibilityActionDelegate {
    var onDismissPreviewHandler: (() -> Void)? {
        guard let host = host as? MarkersAndRoutesListHostViewController else {
            return nil
        }
        
        return host.onDismissPreviewHandler
    }
    
    func didSelectLocationAction(_ action: LocationAction, entity: POI) {
        GDATelemetry.track(action.telemetryEvent, with: ["context": "", "source": "accessibility_action"])
        
        let detail = LocationDetail(entity: entity, telemetryContext: "markers")
        
        LocationDetail.fetchNameAndAddressIfNeeded(for: detail) { [weak self] (newValue) in
            guard let `self` = self else {
                return
            }
            
            self.didSelectLocationAction(action, detail: newValue)
        }
    }
    
    private func didSelectLocationAction(_ action: LocationAction, detail: LocationDetail) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            guard action.isEnabled else {
                // Do nothing if the action is disabled
                return
            }
            
            do {
                switch action {
                case .save, .edit:
                    // No-op. Navigating the the save/edit marker screen is handled directly in `MarkersList` and `RoutesList`
                    break
                    
                case .beacon:
                    // Set a beacon on the given location
                    // and segue to the home view
                    try LocationActionHandler.beacon(locationDetail: detail)
                    self.popToRootViewController(animated: true)
                    
                case .preview:
                    if AppContext.shared.isStreetPreviewing {
                        let alert = LocationActionAlert.restartPreview { [weak self] (_) in
                            self?.host?.performSegue(withIdentifier: "UnwindPreviewView", sender: detail)
                        }
                        
                        self.host?.present(alert, animated: true, completion: nil)
                    } else {
                        self.host?.performSegue(withIdentifier: "PreviewView", sender: detail)
                    }
                    
                case .share:
                    // Create a URL to share a marker at the given location
                    let url = try LocationActionHandler.share(locationDetail: detail)
                    // Present the activity view controller
                    let alert = ShareMarkerAlert.shareMarker(url, markerName: detail.displayName)
                    
                    if FirstUseExperience.didComplete(.share) {
                        self.host?.present(alert, animated: true, completion: nil)
                    } else {
                        let firstUseAlert = ShareMarkerAlert.firstUseExperience(dismissHandler: { [weak self] _ in
                            guard let `self` = self else {
                                return
                            }
                            
                            FirstUseExperience.setDidComplete(for: .share)
                            
                            self.host?.present(alert, animated: true, completion: nil)
                        })
                        
                        self.host?.present(firstUseAlert, animated: true, completion: nil)
                    }
                }
            } catch let error as LocationActionError {
                let alert = LocationActionAlert.alert(for: error)
                self.host?.present(alert, animated: true, completion: nil)
            } catch {
                let alert = LocationActionAlert.alert(for: error)
                self.host?.present(alert, animated: true, completion: nil)
            }
        }
    }
}
