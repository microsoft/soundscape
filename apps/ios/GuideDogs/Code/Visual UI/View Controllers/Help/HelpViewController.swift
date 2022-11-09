//
//  HelpViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import SwiftUI

class HelpPage {
    /// This should contain a localized String
    let title: String
    let index: IndexPath
    let telemetryLabel: String
    
    init(title: String, index: IndexPath, telemetryLabel: String) {
        self.title = title
        self.index = index
        self.telemetryLabel = telemetryLabel
    }
}

class TextHelpPage: HelpPage {
    let text: [String]
    
    init(title: String, text: [String], index: IndexPath, telemetryLabel: String) {
        self.text = text
        super.init(title: title, index: index, telemetryLabel: telemetryLabel)
    }
}

struct SectionedHelpPageDeepLink {
    let url: URL
    let title: String
}

/// What/When/How help page
class SectionedHelpPage: HelpPage {
    /// This should contain a localized String
    let what: [String]
    /// This should contain a localized String
    let when: [String]
    /// This should contain a localized String
    let how: [String]
    
    /// This is a URL for a deeplink to another app or additional documentation on the internet
    let link: SectionedHelpPageDeepLink?
    
    init(title: String, what: [String], when: [String], how: [String], link: SectionedHelpPageDeepLink? = nil, index: IndexPath, telemetryLabel: String) {
        self.what = what
        self.when = when
        self.how = how
        self.link = link
        super.init(title: title, index: index, telemetryLabel: telemetryLabel)
    }
}

struct FAQ {
    /// This should contain a localized String
    let question: String
    
    /// This should contain a localized String
    let answer: String
    
    init(_ question: String, _ answer: String) {
        self.question = question
        self.answer = answer
    }
}

struct FAQSection {
    /// This should contain a localized String
    let heading: String
    
    /// A list of localized FAQs
    let faqs: [FAQ]
}

class FAQListHelpPage: HelpPage {
    /// A list of localized FAQs
    let sections: [FAQSection]
    
    init(title: String, sections: [FAQSection], index: IndexPath, telemetryLabel: String) {
        self.sections = sections
        super.init(title: title, index: index, telemetryLabel: telemetryLabel)
    }
}

// MARK: -

class HelpViewController: BaseTableViewController {
    
    // MARK: Properties
    
    private var helpPages = [
        
        // Configuration
        TextHelpPage(title: GDLocalizedString("voice.voices"),
                     text: [GDLocalizedString("help.config.voices.content")],
                     index: IndexPath(row: 0, section: Section.configuration),
                     telemetryLabel: "help.config.voices"),
        
        // Audio AR Headsets - AirPods
        SectionedHelpPage(title: GDLocalizedString("help.using_headsets.airpods.title"),
                          what: [GDLocalizedString("help.using_headsets.airpods.what")],
                          when: [GDLocalizedString("help.using_headsets.airpods.when")],
                          how: [GDLocalizedString("help.using_headsets.airpods.how.1"),
                                GDLocalizedString("help.using_headsets.airpods.how.2")],
                          index: IndexPath(row: 1, section: Section.configuration),
                          telemetryLabel: "help.ar_headsets.airpods"),
        
        // Using Media Controls
        SectionedHelpPage(title: GDLocalizedString("help.remote.page_title"),
                          what: [GDLocalizedString("help.text.remote_control.what")],
                          when: [GDLocalizedString("help.text.remote_control.when")],
                          how: [GDLocalizedString("help.text.remote_control.how")],
                          index: IndexPath(row: 2, section: Section.configuration),
                          telemetryLabel: "help.media_controls"),
        
        // Destination Beacons
        SectionedHelpPage(title: GDLocalizedString("beacon.audio_beacon"),
                          what: [GDLocalizedString("help.text.destination_beacons.what")],
                          when: [GDLocalizedString("help.text.destination_beacons.when")],
                          how: [GDLocalizedString("help.text.destination_beacons.how.1"),
                                GDLocalizedString("help.text.destination_beacons.how.2"),
                                GDLocalizedString("help.text.destination_beacons.how.3")],
                          index: IndexPath(row: 0, section: Section.beaconsAndCallouts),
                          telemetryLabel: "help.destinations"),

        // Automatic Callouts
        SectionedHelpPage(title: GDLocalizedString("callouts.automatic_callouts"),
                          what: [GDLocalizedString("help.text.automatic_callouts.what")],
                          when: [GDLocalizedString("help.text.automatic_callouts.when.1"),
                                 GDLocalizedString("help.text.automatic_callouts.when.2"),
                                 GDLocalizedString("help.text.automatic_callouts.when.3")],
                          how: [GDLocalizedString("help.text.automatic_callouts.how.1"),
                                GDLocalizedString("help.text.automatic_callouts.how.2")],
                          index: IndexPath(row: 1, section: Section.beaconsAndCallouts),
                          telemetryLabel: "help.auto_callouts"),
        
        // My Location
        SectionedHelpPage(title: GDLocalizedString("directions.my_location"),
                          what: [GDLocalizedString("help.text.my_location.what")],
                          when: [GDLocalizedString("help.text.my_location.when")],
                          how: [GDLocalizedString("help.text.my_location.how")],
                          index: IndexPath(row: 0, section: Section.homeScreen),
                          telemetryLabel: "help.locate"),
        
        // Around Me
        SectionedHelpPage(title: GDLocalizedString("help.orient.page_title"),
                          what: [GDLocalizedString("help.text.around_me.what")],
                          when: [GDLocalizedString("help.text.around_me.when")],
                          how: [GDLocalizedString("help.text.around_me.how")],
                          index: IndexPath(row: 1, section: Section.homeScreen),
                          telemetryLabel: "help.orient"),
        
        // Ahead of Me
        SectionedHelpPage(title: GDLocalizedString("help.explore.page_title"),
                          what: [GDLocalizedString("help.text.ahead_of_me.what")],
                          when: [GDLocalizedString("help.text.ahead_of_me.when")],
                          how: [GDLocalizedString("help.text.ahead_of_me.how")],
                          index: IndexPath(row: 2, section: Section.homeScreen),
                          telemetryLabel: "help.explore"),
        
        // Nearby Markers
        SectionedHelpPage(title: GDLocalizedString("callouts.nearby_markers"),
                          what: [GDLocalizedString("help.text.nearby_markers.what")],
                          when: [GDLocalizedString("help.text.nearby_markers.when")],
                          how: [GDLocalizedString("help.text.nearby_markers.how")],
                          index: IndexPath(row: 3, section: Section.homeScreen),
                          telemetryLabel: "help.nearby_markers"),
        
        // Markers
        TextHelpPage(title: GDLocalizedString("markers.title"),
                     text: [GDLocalizedString("help.text.markers.content.1"),
                            GDLocalizedString("help.text.markers.content.2"),
                            GDLocalizedString("help.text.markers.content.3")],
                     index: IndexPath(row: 0, section: Section.markersAndRoutes),
                     telemetryLabel: "help.markers"),
        
        // Routes
        SectionedHelpPage(title: GDLocalizedString("routes.title"),
                          what: [GDLocalizedString("help.text.routes.content.what")],
                          when: [GDLocalizedString("help.text.routes.content.when")],
                          how: [
                            GDLocalizedString("help.text.routes.content.how.1"),
                            GDLocalizedString("help.text.routes.content.how.2"),
                            GDLocalizedString("help.text.routes.content.how.3")
                          ],
                          index: IndexPath(row: 1, section: Section.markersAndRoutes),
                          telemetryLabel: "help.routes"),
        
        // Creating Markers
        TextHelpPage(title: GDLocalizedString("help.creating_markers.page_title"),
                     text: [GDLocalizedString("help.text.creating_markers.content.1"),
                            GDLocalizedString("help.text.creating_markers.content.2")],
                     index: IndexPath(row: 2, section: Section.markersAndRoutes),
                     telemetryLabel: "help.creating_markers"),
        
        // Customizing Markers
        TextHelpPage(title: GDLocalizedString("help.edit_markers.page_title"),
                     text: [GDLocalizedString("help.text.customizing_markers.content.1"),
                            GDLocalizedString("help.text.customizing_markers.content.2")],
                     index: IndexPath(row: 3, section: Section.markersAndRoutes),
                     telemetryLabel: "help.edit_markers"),
        
        // Frequently Asked Questions
        FAQListHelpPage(title: GDLocalizedString("faq.title"),
                        sections: [FAQSection(heading: GDLocalizedString("faq.section.what_is_soundscape"),
                                              faqs: [FAQ(GDLocalizedString("faq.when_to_use_soundscape.question"), GDLocalizedString("faq.when_to_use_soundscape.answer")),
                                                     FAQ(GDLocalizedString("faq.markers_function.question"), GDLocalizedString("faq.markers_function.answer"))]),
                                   FAQSection(heading: GDLocalizedString("faq.section.getting_the_best_experience"),
                                              faqs: [FAQ(GDLocalizedString("faq.what_can_I_set.question"), GDLocalizedString("faq.what_can_I_set.answer")),
                                                     FAQ(GDLocalizedString("faq.how_to_use_beacon.question"), GDLocalizedString("faq.how_to_use_beacon.answer")),
                                                     FAQ(GDLocalizedString("faq.why_does_beacon_disappear.question"), GDLocalizedString("faq.why_does_beacon_disappear.answer")),
                                                     FAQ(GDLocalizedString("faq.beacon_on_address.question"), GDLocalizedString("faq.beacon_on_address.answer")),
                                                     FAQ(GDLocalizedString("faq.beacon_on_home.question"), GDLocalizedString("faq.beacon_on_home.answer")),
                                                     FAQ(GDLocalizedString("faq.how_close_to_destination.question"), GDLocalizedString("faq.how_close_to_destination.answer")),
                                                     FAQ(GDLocalizedString("faq.turn_beacon_back_on.question"), GDLocalizedString("faq.turn_beacon_back_on.answer")),
                                                     FAQ(GDLocalizedString("faq.road_names.question"), GDLocalizedString("faq.road_names.answer")),
                                                     FAQ(GDLocalizedString("faq.why_not_every_business.question"), GDLocalizedString("faq.why_not_every_business.answer")),
                                                     FAQ(GDLocalizedString("faq.callouts_stopping_in_vehicle.question"), GDLocalizedString("faq.callouts_stopping_in_vehicle.answer")),
                                                     FAQ(GDLocalizedString("faq.miss_a_callout.question"), GDLocalizedString("faq.miss_a_callout.answer"))]),
                                   FAQSection(heading: GDLocalizedString("faq.section.how_soundscape_works"),
                                              faqs: [FAQ(GDLocalizedString("faq.supported_phones.question"), GDLocalizedString("faq.supported_phones.answer")),
                                                     FAQ(GDLocalizedString("faq.supported_headsets.question"), GDLocalizedString("faq.supported_headsets.answer")),
                                                     FAQ(GDLocalizedString("faq.battery_impact.question"), GDLocalizedString("faq.battery_impact.answer")),
                                                     FAQ(GDLocalizedString("faq.sleep_mode_battery.question"), GDLocalizedString("faq.sleep_mode_battery.answer")),
                                                     FAQ(GDLocalizedString("faq.snooze_mode_battery.question"), GDLocalizedString("faq.snooze_mode_battery.answer")),
                                                     FAQ(GDLocalizedString("faq.headset_battery_impact.question"), GDLocalizedString("faq.headset_battery_impact.answer")),
                                                     FAQ(GDLocalizedString("faq.background_battery_impact.question"), GDLocalizedString("faq.background_battery_impact.answer")),
                                                     FAQ(GDLocalizedString("faq.mobile_data_use.question"), GDLocalizedString("faq.mobile_data_use.answer")),
                                                     FAQ(GDLocalizedString("faq.difference_from_map_apps.question"), GDLocalizedString("faq.difference_from_map_apps.answer")),
                                                     FAQ(GDLocalizedString("faq.use_with_wayfinding_apps.question"), GDLocalizedString("faq.use_with_wayfinding_apps.answer")),
                                                     FAQ(GDLocalizedString("faq.controlling_what_you_hear.question"), GDLocalizedString("faq.controlling_what_you_hear.answer")),
                                                     FAQ(GDLocalizedString("faq.holding_phone_flat.question"), GDLocalizedString("faq.holding_phone_flat.answer")),
                                                     FAQ(GDLocalizedString("faq.personalize_experience.question"), GDLocalizedString("faq.personalize_experience.answer")),
                                                     FAQ(GDLocalizedString("faq.what_is_osm.question"), GDLocalizedString("faq.what_is_osm.answer"))])],
                        index: IndexPath(row: 0, section: Section.faq),
                        telemetryLabel: "help.faq"),
        
        // Tips and Tricks
        TextHelpPage(title: GDLocalizedString("faq.tips.title"),
                     text: [GDLocalizedString("faq.tip.beacon_quiet"),
                            GDLocalizedString("faq.tip.setting_beacon_on_address"),
                            GDLocalizedString("faq.tip.finding_bus_stops"),
                            GDLocalizedString("faq.tip.turning_beacon_off"),
                            GDLocalizedString("faq.tip.turning_off_auto_callouts"),
                            GDLocalizedString("faq.tip.hold_phone_flat"),
                            GDLocalizedString("faq.tip.create_marker_at_bus_stop"),
                            GDLocalizedString("faq.tip.two_finger_double_tap")],
                     index: IndexPath(row: 1, section: Section.faq),
                     telemetryLabel: "help.tips")
    ]
    
    private struct Segues {
        static let OpenHelpPage = "OpenHelpPage"
        static let OpenGenericHelpPage = "OpenGenericHelpPage"
        static let OpenFAQListHelpPage = "OpenFAQListHelpPage"
        static let OpenDestinationTutorial = "destinationTutorial"
        static let OpenMarkerTutorial = "markerTutorial"
        static let OpenOfflinePage = "showOfflineInfo"
    }
    
    private struct Section {
        static let configuration = 0
        static let beaconsAndCallouts = 1
        static let homeScreen = 2
        static let markersAndRoutes = 3
        static let faq = 4
        static let tutorials = 5
        static let moreHelp = 6
    }
    
    private struct Row {
        static let destinations = 0
        static let markers = 1
        static let offline = 2
        static let onboarding = 3
    }
    
    private var currentIndex: IndexPath?
    
    @IBOutlet weak var largeBannerContainerView: UIView!
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("help")
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.moreHelp + 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.configuration: return 4
        case Section.moreHelp: return 1
        case Section.tutorials: return 2
        default:
            if section == Section.faq {
                return helpPages.filter({ $0.index.section == section}).count + 1 // Add one to account for the offline link
            }
            
            return helpPages.filter({ $0.index.section == section}).count
        }
    }
    
    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.configuration: return GDLocalizedString("help.configuration.section.title")
        case Section.beaconsAndCallouts: return GDLocalizedString("settings.help.section.beacons_and_pois")
        case Section.homeScreen: return GDLocalizedString("settings.help.section.home_screen_buttons")
        case Section.markersAndRoutes: return GDLocalizedString("search.view_markers")
        case Section.faq: return GDLocalizedString("faq.title")
        case Section.tutorials: return GDLocalizedString("tutorial.title.plural")
        case Section.moreHelp: return GDLocalizedString("help.more_help.section_title")
        default:  return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case Section.tutorials:
            if AppContext.shared.eventProcessor.activeBehavior is RouteGuidance {
                return GDLocalizedString("help.tutorial.footer.disabled")
            } else {
                return nil
            }
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell", for: indexPath)
        
        switch indexPath.section {
        case Section.moreHelp:
            cell.textLabel?.text = GDLocalizedString("help.support")
            cell.accessibilityTraits = .link
            
        case Section.tutorials:
            if indexPath.row == Row.destinations {
                cell.textLabel?.text = GDLocalizedString("tutorial.beacon.getting_started")
            } else {
                cell.textLabel?.text = GDLocalizedString("tutorial.markers.getting_started")
            }
            
            if AppContext.shared.eventProcessor.activeBehavior is RouteGuidance {
                cell.textLabel?.isEnabled = false
            }
            
        default:
            // Special case for the offline page
            if indexPath.section == Section.faq && indexPath.row == Row.offline {
                cell.textLabel?.text = GDLocalizedString("help.offline.section_title")
                return cell
            }
            
            // Special case for app setup
            if indexPath.section == Section.configuration && indexPath.row == Row.onboarding {
                cell.textLabel?.text = GDLocalizedString("first_launch.help.title")
                return cell
            }
            
            guard let page = helpPages.firstIndex(where: { $0.index == indexPath }) else {
                return cell
            }
            
            cell.textLabel?.text = helpPages[page].title
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentIndex = indexPath
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case Section.moreHelp:
            // Open the DAD website
            UIApplication.shared.open(AppContext.Links.companySupportURL)
            
        case Section.tutorials:
            if indexPath.row == Row.destinations {
                performSegue(withIdentifier: Segues.OpenDestinationTutorial, sender: self)
            } else if indexPath.row == Row.markers {
                performSegue(withIdentifier: Segues.OpenMarkerTutorial, sender: self)
            }
            
        default:
            // Special case for the offline page
            if indexPath.section == Section.faq && indexPath.row == Row.offline {
                performSegue(withIdentifier: Segues.OpenOfflinePage, sender: self)
                return
            }
            
            // Special case for app setup
            if indexPath.section == Section.configuration && indexPath.row == Row.onboarding {
                // Initialize view model
                let viewModel = OnboardingViewModel()
                // Initialize view and hosting controller
                let rootView = OnboardingWelcomeView(context: .help).environmentObject(viewModel)
                let viewController = UIHostingController(rootView: rootView)
                
                // Set dismiss handler
                viewModel.dismiss = {
                    viewController.dismiss(animated: true, completion: nil)
                }
                
                present(viewController, animated: true, completion: nil)
                return
            }
            
            // Other help pages
            guard let page = helpPages.firstIndex(where: { $0.index == currentIndex }) else {
                return
            }
            
            if helpPages[page] is SectionedHelpPage {
                performSegue(withIdentifier: Segues.OpenHelpPage, sender: self)
            } else if helpPages[page] is FAQListHelpPage {
                performSegue(withIdentifier: Segues.OpenFAQListHelpPage, sender: self)
            } else {
                performSegue(withIdentifier: Segues.OpenGenericHelpPage, sender: self)
            }
        }
    }
    
    // MARK: Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        switch segue.destination {
        case let helpVC as HelpPageViewController:
            // Pass the selected object to the new view controller.
            guard let page = helpPages.firstIndex(where: { $0.index == currentIndex }) else { return }
            guard let content = helpPages[page] as? SectionedHelpPage else { return }
            
            helpVC.loadContent(content)
            GDATelemetry.trackScreenView(helpPages[page].telemetryLabel)
            
        case let faqVC as HelpPageFAQListTableViewController:
            // Pass the selected object to the new view controller.
            guard let page = helpPages.firstIndex(where: { $0.index == currentIndex }) else { return }
            guard let content = helpPages[page] as? FAQListHelpPage else { return }
            
            faqVC.loadContent(content)
            GDATelemetry.trackScreenView(helpPages[page].telemetryLabel)
            
        case let genericVC as HelpPageGenericViewController:
            // Pass the selected object to the new view controller.
            guard let page = helpPages.firstIndex(where: { $0.index == currentIndex }) else { return }
            guard let content = helpPages[page] as? TextHelpPage else { return }
            
            genericVC.loadContent(content)
            GDATelemetry.trackScreenView(helpPages[page].telemetryLabel)
            
        case let destinationVC as DestinationTutorialIntroViewController:
            destinationVC.logContext = "help_screen"
            
        case let markerVC as MarkerTutorialViewController:
            markerVC.logContext = "help_screen"
            
        default:
            return
        }
    }
    
    @IBAction func unwindToHome(segue: UIStoryboardSegue) {}
}

// MARK: - LargeBannerContainerView

extension HelpViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerView.setHeight(height)
        tableView.reloadData()
    }
    
}
