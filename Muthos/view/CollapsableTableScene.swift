/**
*  CollapsableTable - Collapsable table view sections with custom section header views.
*
*  CollapsableTableScene.swift
*
*  For usage, see documentation of the classes/symbols listed in this file.
*
*  Copyright (c) 2016 Rob Nash. Licensed under the MIT license, as follows:
*
*  Permission is hereby granted, free of charge, to any person obtaining a copy
*  of this software and associated documentation files (the "Software"), to deal
*  in the Software without restriction, including without limitation the rights
*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*  copies of the Software, and to permit persons to whom the Software is
*  furnished to do so, subject to the following conditions:
*
*  The above copyright notice and this permission notice shall be included in all
*  copies or substantial portions of the Software.
*
*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*  SOFTWARE.
*/

import UIKit

open class CollapsableTableViewController: UIViewController {
    
    override open func viewDidLoad() {
        
        super.viewDidLoad()
        
        guard let tableView = collapsableTableView() else {
            return
        }
        
        guard let nibName = sectionHeaderNibName() else {
            return
        }
        
        guard let reuseID = sectionHeaderReuseIdentifier() else {
            return
        }
        
        tableView.register(UINib(nibName: nibName, bundle: nil), forHeaderFooterViewReuseIdentifier: reuseID)
    }
    
    /*!
    * @discussion Override this method to return a custom table view.
    * @return the table view. Is nil unless overriden.
    */
    open func collapsableTableView() -> UITableView? {
        return nil
    }

    /*!
    * @discussion Override this method to return a custom model for the table view.
    * @return the model for the table view. Is nil unless overriden.
    */
    open func model() -> [CollapsableTableViewSectionModelProtocol]? {
        return nil
    }
        
    /*!
    * @discussion Only one section is visible when the user taps to select a section. Deselecting an open section, closes all sections. By returning 'NO' for this value, then this rule is ignored.
    * @return a boolean indication for conforming to the single open selection rule. Is 'NO' by defualt.
    */
    open func singleOpenSelectionOnly() -> Bool {
        return false
    }

    /*!
    * @discussion Override this method to return the nib name of your UITableViewHeaderFooterView subclass.
    * @return the section header nib name. Is nil unless overriden.
    */
    open func sectionHeaderNibName() -> String? {
        return nil
    }

    open func sectionHeaderReuseIdentifier() -> String? {
        return (sectionHeaderNibName())! + "ID"
    }
    
}

extension CollapsableTableViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        
        guard let model = self.model() else {
            return 0
        }
        
        return model.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let model = self.model() else {
            return 0
        }
        
        let menuSection = model[section]
        
        return (menuSection.isVisible ) ? menuSection.items.count : 0
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let reuseID = self.sectionHeaderReuseIdentifier() else {
            return nil
        }
        
        guard var view = tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseID) as? CollapsableTableViewSectionHeaderProtocol else {
            return nil
        }
        
        guard let model = self.model() else {
            return nil
        }
        
        view.sectionTitleLabel.text = (model[section].title )
        view.interactionDelegate = self
        
        return view as? UIView
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
}

extension CollapsableTableViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        guard let view = view as? CollapsableTableViewSectionHeaderProtocol else {
            return
        }
        
        guard let model = self.model() else {
            return
        }
        
        if (model[section].isVisible ) {
            view.open(false)
        } else {
            view.close(false)
        }
        
    }
}

extension CollapsableTableViewController: CollapsableTableViewSectionHeaderInteractionProtocol {
    
    public func userTappedView<T : UITableViewHeaderFooterView>(_ headerView: T, atPoint location: CGPoint) where T : CollapsableTableViewSectionHeaderProtocol {
        
        guard let tableView = self.collapsableTableView() else {
            return;
        }
            
        guard let tappedSection = sectionForUserSelectionInTableView(tableView, atTouchLocation: location, inView: headerView) else {
            return
        }
        
        guard let collection = self.model() else {
            return
        }
        
        var foundOpenUnchosenMenuSection = false
        
        var section = 0
        
        tableView.beginUpdates()
        
        for var model in collection {
            
            if tappedSection == section {
                
                model.isVisible = !model.isVisible
                
                toggleCollapseTableViewSectionAtSection(section, withModel:model, inTableView: tableView, usingAnimation: (foundOpenUnchosenMenuSection) ? .bottom : .top, forSectionWithHeaderFooterView: headerView)
                
            } else if model.isVisible && self.singleOpenSelectionOnly() {
                
                foundOpenUnchosenMenuSection = true
                
                model.isVisible = !model.isVisible
                
                guard let untappedHeaderView = tableView.headerView(forSection: section) as? CollapsableTableViewSectionHeaderProtocol else {
                    return
                }
                
                toggleCollapseTableViewSectionAtSection(section, withModel: model, inTableView: tableView, usingAnimation: (tappedSection > section) ? .top : .bottom, forSectionWithHeaderFooterView: untappedHeaderView)
            }
            
            section += 1
        }
        
        tableView.endUpdates()
        
    }
    
    fileprivate func toggleCollapseTableViewSectionAtSection(_ section: Int, withModel model: CollapsableTableViewSectionModelProtocol, inTableView tableView:UITableView, usingAnimation animation:UITableViewRowAnimation, forSectionWithHeaderFooterView headerFooterView: CollapsableTableViewSectionHeaderProtocol) {
        
        let indexPaths = self.indexPaths(section, menuSection: model)
        
        if model.isVisible {
            headerFooterView.open(true)
            tableView.insertRows(at: indexPaths, with: animation)
        } else {
            headerFooterView.close(true)
            tableView.deleteRows(at: indexPaths, with: animation)
        }
    }
    
    fileprivate func sectionForUserSelectionInTableView(_ tableView: UITableView, atTouchLocation location:CGPoint, inView view: UIView) -> Int? {
        
        let point = tableView.convert(location, from: view)
        
        for i in 0...(tableView.numberOfSections-1) {
            if tableView.rectForHeader(inSection: i).contains(point) {
                return i
            }
        }
        
        return nil
    }
    
    fileprivate func indexPaths(_ section: Int, menuSection: CollapsableTableViewSectionModelProtocol) -> [IndexPath] {
        
        var collector = [IndexPath]()
        
        for i in 0 ..< menuSection.items.count {
            collector.append(IndexPath(row: i, section: section))
        }
        
        return collector
    }
}
