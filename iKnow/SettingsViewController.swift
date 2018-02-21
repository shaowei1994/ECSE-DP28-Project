//
//  SettingsViewController.swift
//  iKnow
//
//  Created by Shao-Wei Liang on 2018-01-27.
//  Copyright © 2018 Shao-Wei Liang. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    let cellHeight: CGFloat = 50
    let fontSize: CGFloat = 35
    
    let sections: [String] = [
        "Languages",
        "About"
    ]
    
    var languages: [Language] = [
        Language(symbol: "🇨🇦", name: "Canadian English"),
        Language(symbol: "🇨🇳", name: "Simplified Chinese"),
        Language(symbol: "🇹🇼", name: "Traditional Chinese"),
        Language(symbol: "🇯🇵", name: "Japanese"),
        Language(symbol: "🇫🇷", name: "French")
    ]
    
    let abouts: [String]  = [
        "Version",
        "Build"
    ]

    class Language{
        var symbol: String
        var name: String
        
        init(symbol: String, name: String){
            self.symbol = symbol
            self.name = name
        }
    }

    @IBAction func editButtonTapped(_ sender: UIBarButtonItem){
        let tableViewEditingMode = tableView.isEditing
        tableView.setEditing(!tableViewEditingMode, animated: true)
    }

    @IBAction func didSelectDoneButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
        tableView.rowHeight = cellHeight
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return languages.count
        }else{
            return abouts.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath)
        switch (indexPath.section) {
        case 0:
            let language = languages[indexPath.row]
            cell.textLabel?.text = "\(language.symbol) - \(language.name)"
        default:
            let about = abouts[indexPath.row]
            cell.textLabel?.text = "\(about)"
        }
        cell.textLabel?.font = UIFont(name:"Avenir", size:22)
        cell.showsReorderControl = true
        return cell
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        tableView.reloadData()
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let movedLanguageCell = languages.remove(at: fromIndexPath.row)
        languages.insert(movedLanguageCell, at: to.row)
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        languages.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
}
