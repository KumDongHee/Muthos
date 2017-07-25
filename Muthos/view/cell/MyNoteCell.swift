//
//  MyNoteCell.swift
//  Muthos
//
//  Created by 김성재 on 2016. 11. 26..
//
//

import UIKit
import SwiftyJSON
import MGSwipeTableCell

protocol MyNoteCellDelegate {
    func touchedListenButton(cell:MyNoteCell, note: Note)
	func touchedSpeakButton(cell:MyNoteCell, note: Note)
}

class MyNoteCell: MGSwipeTableCell, SpeechRecognizingViewDelegate {
	@IBOutlet weak var thumbImgView: UIImageView!
    @IBOutlet weak var gradeStarArea: UIView!
    @IBOutlet weak var titleLabel: TopAlignedLabel!
	
	//normal
	@IBOutlet weak var dateLabel: UILabel!
	
	//expand
	@IBOutlet weak var arrowImgView: UIImageView!
	@IBOutlet weak var topShadowImgView: UIImageView!
	@IBOutlet weak var previewImgView: UIImageView!
	@IBOutlet weak var setNameLabel: UILabel!
	@IBOutlet weak var shadowImgView: UIImageView!
	@IBOutlet weak var listenButton: UIButton!
	@IBOutlet weak var speakButton: UIButton!
    @IBOutlet weak var talkArea: UIView!

	var cellDelegate: MyNoteCellDelegate?
	
    var note:Note?
    
	var model:JSON? {
		didSet {
            guard let nt = model else {return}
            let note:Note = BookController.buildNoteWithPath(nt)
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            titleLabel.setWidth(gradeStarArea.left - 15 - titleLabel.left)
            titleLabel.setHeight(1000)

            titleLabel.text = note.contents!
            
            titleLabel.sizeToFit()
            setNameLabel.text = "Set " + note.setIndex! + " / 소설"
            dateLabel.text = fmt.string(from: note.date!)
            thumbImgView.image = UIImage(data:BookController.cachedBookResourceData(note.bookId!, resource: note.thumbimage!))
            previewImgView.image = note.backgroundImage!
            
            let grade = nt["grade"].intValue

            for v in gradeStarArea.subviews {
                v.isHidden = true
            }
            
            self.renderGrade(grade:grade)
            self.note = note
		}
	}
	
    func renderGrade(grade:Int) {
        for v in gradeStarArea.subviews {
            v.isHidden = true
        }
        
        if (grade - 1) >= 0 && (grade - 1) < 5 {
            gradeStarArea.subviews[(grade-1)].isHidden = false
        }
        else {
            gradeStarArea.subviews[0].isHidden = false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
		
        // Initialization code
		arrowImgView.isHidden = true
		previewImgView.isHidden = true
		setNameLabel.isHidden = true
		shadowImgView.isHidden = true
        topShadowImgView.isHidden = true
		listenButton.isHidden = true
		speakButton.isHidden = true
        gradeStarArea.isHidden = true
    }

	
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
		previewImgView.isHidden = !selected
        arrowImgView.isHidden = !selected
		setNameLabel.isHidden = !selected
		shadowImgView.isHidden = !selected
        topShadowImgView.isHidden = !selected
		listenButton.isHidden = !selected
		speakButton.isHidden = !selected
        gradeStarArea.isHidden = selected
		
		dateLabel.isHidden = selected
		
        let srv = ApplicationContext.sharedInstance.speechRecognizingView

        titleLabel.setWidth(gradeStarArea.left - 15 - titleLabel.left)
        titleLabel.setHeight(1000)
        
		if selected {
            titleLabel.text = note!.bookTitle!
			titleLabel.textColor = UIColor(hexString: "ffffff")
            srv.display(on: talkArea, model: note!.dialog!)
            srv.startListening(animation: false)
            srv.isPractice = true
            srv.delegate = self

            srv.btnTalkAnswer.isHidden = true
            
            titleLabel.sizeToFit()
            setNameLabel.setY(titleLabel.bottom + 8)
		} else {
            titleLabel.text = note!.contents!
			titleLabel.textColor = UIColor(hexString: "323232")
            
            srv.removeFromSuperview()
		}
    }
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		titleLabel.text = ""
		dateLabel.text = ""
		setNameLabel.text = ""
	}
	
	@IBAction func touchListenButton(_ sender: Any) {
		guard let note = note else {return}
        cellDelegate?.touchedListenButton(cell:self, note: note)
	}

	@IBAction func touchSpeakButton(_ sender: Any) {
		guard let note = note else {return}
        cellDelegate?.touchedSpeakButton(cell:self, note: note)
	}
	
    func speechRecognizingViewDidClickNext(view:SpeechRecognizingView) {
    }
    
    func speechRecognizingViewDidClickRetry(view:SpeechRecognizingView) {
    }
    
    func speechRecognizingViewDidFinished(view:SpeechRecognizingView, grade:Int) {
        guard let nt = model else {return}
        ApplicationContext.sharedInstance.userViewModel.updateGradeOnMyNote(path:nt["path"], grade:grade)
        self.renderGrade(grade:grade)
    }
}
