//
//  Fence.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 4/21/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import UIKit
import CoreData

class Fence: NSManagedObject {
    
    class func createFence(matching fenceInfo: NewFence, in context: NSManagedObjectContext) throws -> Fence {
        let fence = Fence(context: context)
        fence.id = fenceInfo.id
        fence.name = fenceInfo.name
        fence.latitude = fenceInfo.latitude
        fence.longitude = fenceInfo.longitude
        fence.radius = fenceInfo.radius
        return fence
    }
}
