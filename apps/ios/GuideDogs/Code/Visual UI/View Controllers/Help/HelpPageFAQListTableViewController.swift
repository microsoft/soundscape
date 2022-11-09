//
//  HelpPageFAQListTableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class HelpPageFAQListTableViewController: BaseTableViewController {
    
    private struct Segue {
        static let OpenFAQHelpPage = "OpenFAQHelpPage"
    }
    
    private struct Cell {
        static let QuestionCell = "QuestionCell"
    }

    private var faqList: FAQListHelpPage!
    
    private var currentIndex: IndexPath?
    
    func loadContent(_ content: FAQListHelpPage) {
        faqList = content
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return faqList.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < faqList.sections.count else {
            return 0
        }
        
        return faqList.sections[section].faqs.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < faqList.sections.count else {
            return nil
        }
        
        return faqList.sections[section].heading
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.QuestionCell, for: indexPath)
        
        guard indexPath.section < faqList.sections.count, indexPath.row < faqList.sections[indexPath.section].faqs.count else {
            return cell
        }
        
        cell.textLabel?.text = faqList.sections[indexPath.section].faqs[indexPath.row].question
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.section < faqList.sections.count, indexPath.row < faqList.sections[indexPath.section].faqs.count else {
            return
        }
        
        currentIndex = indexPath
        
        performSegue(withIdentifier: Segue.OpenFAQHelpPage, sender: self)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? HelpPageFAQViewController else {
            return
        }
        
        guard let index = currentIndex else {
            return
        }
        
        vc.faq = faqList.sections[index.section].faqs[index.row]
    }

}
