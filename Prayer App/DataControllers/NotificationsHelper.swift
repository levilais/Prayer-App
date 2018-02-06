//
//  NotificationsHelper.swift
//  Prayer App
//
//  Created by Levi on 2/3/18.
//  Copyright © 2018 App Volks. All rights reserved.
//

import Foundation

class NotificationsHelper {
    func sendPrayerNotification(messagingTokens: [String]) {
        if let firstName = CurrentUser.currentUser.firstName {
            for token in messagingTokens {
                print("sending to token: \(token)")
                if let url = URL(string: "https://fcm.googleapis.com/fcm/send") {
                    var request = URLRequest(url: url)
                    request.allHTTPHeaderFields = ["Content-Type":"application/json","Authorization":"key=AAAAWqjLV7Q:APA91bGty5xwztEa8z70MVCMJy-djszfCFlPTvWRBWVghpglVOzbRCCYWXX6b2fEqVmuN69FGuDJLuKtnvSwgxD81pCUnIGLIlpviavOmtRACff2epmiiKEmseGOI4X4xV_U2Y5e2E51"]
                    request.httpMethod = "POST"
                    request.httpBody = "{\"to\":\"\(token)\",\"notification\":{\"title\":\"\(firstName) has sent you a Prayer request\"}}".data(using: .utf8)
                    URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
                        if error != nil {
                            print(error!.localizedDescription)
                        }
                        }.resume()
                }
            }
        }
    }
    
    func sendInviteNotification(messagingTokens: [String]) {
        if let firstName = CurrentUser.currentUser.firstName {
            if let lastName = CurrentUser.currentUser.lastName {
                for token in messagingTokens {
                    if let url = URL(string: "https://fcm.googleapis.com/fcm/send") {
                        var request = URLRequest(url: url)
                        request.allHTTPHeaderFields = ["Content-Type":"application/json","Authorization":"key=AAAAWqjLV7Q:APA91bGty5xwztEa8z70MVCMJy-djszfCFlPTvWRBWVghpglVOzbRCCYWXX6b2fEqVmuN69FGuDJLuKtnvSwgxD81pCUnIGLIlpviavOmtRACff2epmiiKEmseGOI4X4xV_U2Y5e2E51"]
                        request.httpMethod = "POST"
                        request.httpBody = "{\"to\":\"\(token)\",\"notification\":{\"title\":\"You're Invited!\",\"body\":\"\(firstName) \(lastName) has invited you to join their Prayer Circle.\"}}".data(using: .utf8)
                        URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
                            if error != nil {
                                print(error!.localizedDescription)
                            }
                        }.resume()
                    }
                }
            }
        }
    }
    
    func sendAcceptNotification(messagingTokens: [String]) {
        if let firstName = CurrentUser.currentUser.firstName {
            for token in messagingTokens {
                if let url = URL(string: "https://fcm.googleapis.com/fcm/send") {
                    var request = URLRequest(url: url)
                    request.allHTTPHeaderFields = ["Content-Type":"application/json","Authorization":"key=AAAAWqjLV7Q:APA91bGty5xwztEa8z70MVCMJy-djszfCFlPTvWRBWVghpglVOzbRCCYWXX6b2fEqVmuN69FGuDJLuKtnvSwgxD81pCUnIGLIlpviavOmtRACff2epmiiKEmseGOI4X4xV_U2Y5e2E51"]
                    request.httpMethod = "POST"
                    request.httpBody = "{\"to\":\"\(token)\",\"notification\":{\"title\":\"Good News!\",\"body\":\"\(firstName) has accepted your Prayer Circle invitation\"}}".data(using: .utf8)
                    URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
                        if error != nil {
                            print(error!.localizedDescription)
                        }
                        }.resume()
                }
            }
        }
    }
    
    func sendAgreedNotification(messagingTokens: [String]) {
        if let firstName = CurrentUser.currentUser.firstName {
            for token in messagingTokens {
                print("token: \(token)")
                if let url = URL(string: "https://fcm.googleapis.com/fcm/send") {
                    var request = URLRequest(url: url)
                    request.allHTTPHeaderFields = ["Content-Type":"application/json","Authorization":"key=AAAAWqjLV7Q:APA91bGty5xwztEa8z70MVCMJy-djszfCFlPTvWRBWVghpglVOzbRCCYWXX6b2fEqVmuN69FGuDJLuKtnvSwgxD81pCUnIGLIlpviavOmtRACff2epmiiKEmseGOI4X4xV_U2Y5e2E51"]
                    request.httpMethod = "POST"
                    request.httpBody = "{\"to\":\"\(token)\",\"notification\":{\"title\":\"Amen...\",\"body\":\"\(firstName) said a Prayer for you today.\"}}".data(using: .utf8)
                    URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
                        if error != nil {
                            print(error!.localizedDescription)
                        }
                    }.resume()
                }
            }
        }
    }
}
