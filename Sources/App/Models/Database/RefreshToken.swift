//
//  RefreshToken.swift
//  App
//
//  Created by Mykhailo Bondarenko on 13.04.2020.
//

import Vapor
import FluentSQLite

final class RefreshToken: SQLiteModel {
    
    fileprivate enum Constants {
        static let refreshTokenTime: TimeInterval = 60 * 24 * 60 * 60
    }
    
    var id: Int?
    var token: String
    var expiredAt: Date
    var userID: User.ID
    
    init(id: Int? = nil,
         token: String,
         expiredAt: Date = Date().addingTimeInterval(Constants.refreshTokenTime),
         userID: User.ID) {
        self.id = id
        self.token = token
        self.expiredAt = expiredAt
        self.userID = userID
    }
    
    func updateExpiredDate() {
        self.expiredAt = Date().addingTimeInterval(Constants.refreshTokenTime)
    }
}

extension RefreshToken {
    var user: Parent<RefreshToken, User> {
        return self.parent(\.userID)
    }
}

extension RefreshToken: Content { }

extension RefreshToken: SQLiteMigration { }

extension RefreshToken: Parameter { }
