//
//  ViewController.swift
//  Emoji Search
//
//  Created by Nathan Ansel on 12/28/15.
//  Copyright © 2015 Nathan Ansel. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating, CustomSearchControllerDelegate {

  // MARK: - Properties
  var emojazz = NSMutableDictionary()
  var emojiObjects = NSMutableArray()
  var filteredEmoji = NSMutableArray()
  var filteredCatagories = NSMutableArray()
  let emojiCatagories = NSMutableArray()
  let sortedEmojiObjects = NSMutableArray()
  var searchController: CustomSearchController!
  
  var keyboardFrame: CGRect!
  @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
  
  @IBOutlet var tableView: UITableView!
  
  
  
  // MARK: - Methods
  
  // MARK: Overrides
  override func viewDidLoad() {
    super.viewDidLoad()
    setNeedsStatusBarAppearanceUpdate()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "rotated:", name: UIDeviceOrientationDidChangeNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "rotated:", name: UIApplicationWillEnterForegroundNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "URLSearch:", name: "search", object: nil)
    
    let parser = EmojiParser()
    emojazz = parser.parseEmoji()
    emojiObjects = parser.parseEmojiToObjects()
    
    let tempEmojiCatagories = NSMutableArray()
    let tempSortedEmojiObjects = NSMutableArray()
    
    for item in emojiObjects {
      if tempEmojiCatagories.indexOfObject((item as! Emoji).catagory) == NSNotFound {
        tempEmojiCatagories.addObject((item as! Emoji).catagory)
        tempSortedEmojiObjects.addObject(NSMutableArray())
        emojiCatagories.addObject("")
        sortedEmojiObjects.addObject(NSMutableArray())
      }
    }
    
    /// Catagories:
    /// In keyboard:
    ///   smileys & people
    ///   animals & nature
    ///   food & drink
    ///   activity
    ///   travel & places
    ///   objects
    ///   symbols
    ///   flags
    ///
    /// In app:
    ///   smileys & people
    ///   animals & nature
    ///   food & drink
    ///   activity
    ///   travel & places
    ///   objects & symbols
    ///   celebration
    ///   flags
    var count = 0
    var index = 0
    for item in tempEmojiCatagories {
      let category = item as! String
      switch category {
        case "Smileys & People":
          index = 0
        case "Animals & Nature":
          index = 1
        case "Food & Drink":
          index = 2
        case "Activity":
          index = 3
        case "Travel & Places":
          index = 4
        case "Objects & Symbols":
          index = 5
        case "Celebration":
          index = 6
        case "Flags":
          index = 7
        default:
          print("ERROR: Catagory is not valid, not added to sorted array.")
          index = -1
      }
      if index > -1 {
        emojiCatagories[index] = category
        sortedEmojiObjects[index] = tempSortedEmojiObjects[count]
      }
      count += 1
    }
    
    // Sort the emoji objects by name
    emojiObjects.sortUsingComparator({ (firstObject: AnyObject, secondObject: AnyObject) -> NSComparisonResult in
      (firstObject as! Emoji).name.compare((secondObject as! Emoji).name)
    })
    
    // Sort the emoji objects into catagories
    for item in emojiObjects {
      sortedEmojiObjects[emojiCatagories.indexOfObject((item as! Emoji).catagory)].addObject((item as! Emoji))
    }
    
    tableView.delegate = self
    tableView.dataSource = self
    
    // Setup the Search Controller
    configureSearchController()
    
    ////////////////////////////////////////////////////////////////////////////////
    
    parser.parseEmojiObjectsToJSON(emojiObjects)
    tableViewHeightConstraint.constant = view.frame.size.height - 70
  }
  
  
  
  func configureSearchController() {
    searchController = CustomSearchController(searchResultsController: self, searchBarFrame: CGRectMake(0.0, 20.0, self.view.frame.size.width, 50.0), searchBarAccentColor: UIColor.orangeColor(), searchBarTintColor: UIColor.blackColor())
    definesPresentationContext = true
    searchController.dimsBackgroundDuringPresentation = false
    searchController.customSearchBar.placeholder = "Search by keyword or category"
    //tableView.tableHeaderView = searchController.customSearchBar
    self.view.addSubview(searchController.customSearchBar)
    searchController.customDelegate = self
  }
  
  
  
  override func viewWillAppear(animated: Bool) {
    searchController.customSearchBar.becomeFirstResponder()
  }
  
  
  
  
  // MARK: - Table View
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    if searchController.customSearchBar.text! == "" {
      return emojiCatagories.count
    }
    return filteredCatagories.count
  }
  
  
  
  
//  func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
//    var indexArray = [String]()
//    for categoryName in emojiCatagories {
//      let name = categoryName as! String
//      let firstChar = name[name.startIndex]
//      indexArray.append(String(firstChar))
//    }
//    return indexArray
//  }
  
  
  
  
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if searchController.customSearchBar.text! == "" {
      return sortedEmojiObjects[section].count
    }
    return filteredEmoji[section].count
  }
  
  
  
  
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    
    if searchController.customSearchBar.text! == "" {
      let emoji = sortedEmojiObjects[indexPath.section][indexPath.row] as! Emoji
      cell.textLabel!.text = emoji.symbol
      cell.detailTextLabel!.text = emoji.name
    }
    else {
      let emoji = filteredEmoji[indexPath.section][indexPath.row] as! Emoji
      cell.textLabel!.text = emoji.symbol
      cell.detailTextLabel!.text = emoji.name
    }
    return cell
  }
  
  
  
  
  
  func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
    let cell = tableView.cellForRowAtIndexPath(indexPath)
    UIPasteboard.generalPasteboard().string = cell?.textLabel!.text
    
    let window = UIApplication.sharedApplication().windows.last
    let hud = MBProgressHUD.showHUDAddedTo(window, animated: true)
    hud.mode = MBProgressHUDMode.Text
    hud.labelText = (cell?.textLabel!.text)! + " ➡️ 📋"
    hud.detailsLabelText = "Copied!"
    hud.margin = 20.0
    hud.removeFromSuperViewOnHide = true
    hud.hide(true, afterDelay: 1.0)
  
    return indexPath
  }
  
  
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  
  
  
  
  func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if searchController.customSearchBar.text! == "" {
      return emojiCatagories[section] as? String
    }
    return filteredCatagories[section] as? String
  }

  
  
  func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
    let cell = tableView.cellForRowAtIndexPath(indexPath)
    print(cell?.textLabel!.text)
    self.performSegueWithIdentifier("toDetail", sender: indexPath)
  }
  
  
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "toDetail" {
      let cell = tableView.cellForRowAtIndexPath(sender as! NSIndexPath)
      let emoji = cell?.textLabel!.text
      var emojiObject = emojiObjects[0] as! Emoji
      for item in emojiObjects {
        emojiObject = item as! Emoji
        if emojiObject.symbol == emoji {
          break
        }
      }
      let detailView = segue.destinationViewController as! DetailViewController
      detailView.emojiObject = emojiObject
//      segue.destinationViewController = DetailViewController()
//      destinationViewController.emojiObject = emojiObject
    }
  }
  
  
  
  
  
  ///
  ///  Search the list of Emoji objects for anything matching the search string
  ///  and put it in the filteredEmoji list for display purposes.
  ///
  /// - author: Nathan Ansel
  /// - parameter searchText: The search string to be used when searching the
  ///                         emoji objects.
  ///
  func filterContentForSearchText(searchText: String) {
    // Clear out the old search
    filteredEmoji.removeAllObjects()
    filteredCatagories.removeAllObjects()
    var addEmoji = false
    
    // For each of the search terms
    for word in searchText.componentsSeparatedByString(" ") {
      // For each of the emoji in the JSON
      for emoji in emojiObjects {
        let emojiObject = emoji as! Emoji
        
        // See if any part of the emoji matches the word if so we will add it
        for keyword in emojiObject.keywords {
          if keyword.lowercaseString.containsString(word.lowercaseString) {
            addEmoji = true
          }
        }
        if !addEmoji
          && (emojiObject.name.lowercaseString.containsString(word.lowercaseString)
            || emojiObject.symbol.containsString(word)) {
              addEmoji = true
        }
        
        // Actually add the emoji object to the list of filtered
        if addEmoji {
          // But first add the catagory if it is a new one
          if filteredCatagories.indexOfObject(emojiObject.catagory) == NSNotFound {
            filteredCatagories.addObject(emojiObject.catagory)
            filteredEmoji.addObject(NSMutableArray())
          }
          // Now grab the index and add the emoji object
          let catagoryIndex = filteredCatagories.indexOfObject(emojiObject.catagory)
          if filteredEmoji[catagoryIndex].indexOfObject(emojiObject) == NSNotFound {
            filteredEmoji[catagoryIndex].addObject(emojiObject)
          }
          // Set this back to false so all emoji don't get added
          addEmoji = false
        }
      }
    }
    // So you can see the changes
    tableView.reloadData()
  }

  
  
  
  // MARK: UISearchResultsUpdating delegate function
  
  func updateSearchResultsForSearchController(searchController: UISearchController) {
    guard let searchString = searchController.searchBar.text else {
      return
    }
    
    filterContentForSearchText(searchString)
    
    //tableView.reloadData()
  }

  
  
  
  
  // MARK: CustomSearchControllerDelegate functions
  
  func didStartSearching() {
    //tableView.reloadData()
  }
  
  
  func didTapOnSearchButton() {
    //tableView.reloadData()
  }
  
  
  func didChangeSearchText(searchText: String) {
    filterContentForSearchText(searchText)
    //tableView.reloadData()
  }
  
  
  
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return .LightContent
  }
  
  func keyboardDidShow(notification: NSNotification) {
    keyboardFrame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
    
    tableViewHeightConstraint.constant = view.frame.size.height - keyboardFrame.size.height - 70
    searchController.customSearchBar.frame = CGRectMake(0.0, 20.0, self.view.frame.size.width, 50.0)
  }
  
  func keyboardWillHide(notification: NSNotification) {
    tableViewHeightConstraint.constant = view.frame.size.height - 70
    searchController.customSearchBar.frame = CGRectMake(0.0, 20.0, self.view.frame.size.width, 50.0)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return false
  }
  
  
  func rotated(notification: NSNotification) {
    searchController.customSearchBar.frame = CGRectMake(0.0, 20.0, self.view.frame.size.width, 50.0)
  }
  
  func URLSearch(notification: NSNotification) {
    let searchString = notification.object as! String
    filterContentForSearchText(searchString)
    searchController.customSearchBar.text = searchString
  }


}

