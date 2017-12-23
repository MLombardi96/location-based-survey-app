//
//  AvailableSurveysTableViewCell.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 12/22/17.
//  Copyright © 2017 Mitchell Lombardi. All rights reserved.
//

import UIKit

class AvailableSurveysTableViewCell: UITableViewCell {
    
    //MARK: Properties
    @IBOutlet weak var surveyTitle: UILabel!
    @IBOutlet weak var surveyDemoDescription: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        
        
        //TODO: when selected, and outside geofence open google maps in different view
        
        //TODO: when selected, and within geofence start questionaire
    }

}
