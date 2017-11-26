//
//  CurrentUser.swift
//  Prayer App
//
//  Created by Levi on 11/25/17.
//  Copyright © 2017 App Volks. All rights reserved.
//


import Foundation

class CurrentUser {
    static var isLoggedIn: Bool?
    static var hasAllowedContactAccess = false
    static var circleMembers = [CircleUser]()
}
