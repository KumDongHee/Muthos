//
//  MyNoteCont.swift
//  Muthos
//
//  Created by 김성재 on 2016. 1. 22..
//  Copyright © 2016년 김성재. All rights reserved.
//

import UIKit
import SwiftyJSON
import MGSwipeTableCell

class MyNoteCont: DefaultCont, UITableViewDelegate, UITableViewDataSource, MyNoteCellDelegate, MGSwipeTableCellDelegate {
    var notes:[JSON] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "My note"
        
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(hexString: "e8e8e8")
        
        tableView.register(UINib(nibName: "MyNoteCell", bundle: nil), forCellReuseIdentifier: "MyNoteCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.showLine()
        reloadAll()
    }
	
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func reloadAll() {
        if let notes = ApplicationContext.currentUser.validateMyNotes().array {
            self.notes = notes
        }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:MyNoteCell = tableView.dequeueReusableCell(withIdentifier: "MyNoteCell") as! MyNoteCell
        let note = notes[indexPath.row]
        
        cell.model = note
        cell.selectionStyle = .none
		cell.cellDelegate = self
        cell.delegate = self
		
        let trashButton = MGSwipeButton(title: "", icon: UIImage(named: "mynote_icon_flick_trash"), backgroundColor: UIColor(hexString: "f64d2b"),
                                        callback: {(sender: MGSwipeTableCell!) -> Bool in
                                            ApplicationContext.sharedInstance.userViewModel.toggleMyNotePath(note["path"])
                                            self.perform(#selector(MyNoteCont.reloadAll), with: nil, afterDelay: 0.2)
                                return true })
        
        trashButton.buttonWidth = 67
        
        //configure right buttons
        cell.rightButtons = [trashButton]
        cell.rightSwipeSettings.transition = MGSwipeTransition.static

		if indexPath.row % 2 == 0 {
			cell.backgroundColor = UIColor(hexString: "f3f3f3")
		} else {
			cell.backgroundColor = UIColor(hexString: "fcfcfc")
		}
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            if (selectedIndexPath == indexPath) {
                return 363
            }
        }
        return 67
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.endUpdates()
        
        var cellRect = tableView.rectForRow(at: indexPath)
        cellRect = tableView.convert(cellRect, to: tableView.superview)
        
        if !tableView.frame.contains(cellRect) {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

	func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard !working else { return nil}
		if let selectedindexPath = tableView.indexPathForSelectedRow {
			if indexPath == selectedindexPath {
				//열린 노트 다시 누르면 닫히게 함
				tableView.beginUpdates()
				tableView.deselectRow(at: indexPath, animated: true)
				tableView.endUpdates()
				return nil
			}
		}
		return indexPath
	}
    
    var working:Bool = false
    
    // MARK:- NoteCellDelegate
    func touchedListenButton(cell:MyNoteCell, note: Note) {
        cell.listenButton.isEnabled = false
        cell.speakButton.isEnabled = false
        self.working = true

        let bc:BookController = BookController(book:Book(JSON: ["_id":note.bookId!])!)
        bc.playVoice(bc.cachedBookResourceURL(note.voice!)!, callback: {() -> Bool in
            cell.listenButton.isEnabled = true
            cell.speakButton.isEnabled = true
            self.working = false
            return true
        })
    }
	
	func touchedSpeakButton(cell:MyNoteCell, note: Note) {
        cell.listenButton.isEnabled = false
        cell.speakButton.isEnabled = false
        self.working = true
        
        let bc:BookController = BookController(book:Book(JSON: ["_id":note.bookId!])!)
        _ = bc.recognizer!.recognize(withAnswer: note.contents!, callback: {() -> Bool in
            cell.listenButton.isEnabled = true
            cell.speakButton.isEnabled = true
            self.working = false
            
            print("recognized, " + bc.recognizer!.recognized)
            return true
        })
    }
    
    // MARK:- Actions
    override func touchLeftButton() {
        super.touchLeftButton()
        self.navigationController!.popViewController(animated: true)
    }
    
    // MARK:- MGSwipeTableCellDelegate
    func swipeTableCell(_ cell: MGSwipeTableCell, canSwipe direction: MGSwipeDirection, from point: CGPoint) -> Bool {
        if cell.isSelected {
            return false
        } else {
            return true
        }
    }
    
}
