//
//  Request+Extensions.swift
//  App
//
//  Created by Mykhailo Bondarenko on 13.04.2020.
//

import Vapor
import JWT

extension Request {
    
    var token: String {
        if let token = self.http.headers[.authorization].first {
            return token
        } else {
            return ""
        }
    }
    
    func authorizedUser() throws -> Future<User> {
        let receivedJWT = try JWT<AccessTokenPayload>(from: token, verifiedUsing: JWTConfig.signer)
        let payload = receivedJWT.payload
        //        let userID = try TokenHelpers.getUserID(fromPayloadOf: self.token)
        
        return User.find(payload.userID, on: self).unwrap(or: Abort(.unauthorized, reason: "Authorized user not found"))
    }
}

/// Get user ID from token
//class func getUserID(fromPayloadOf token: String) throws -> Int {
//    do {
//        let receivedJWT = try JWT<AccessTokenPayload>(from: token, verifiedUsing: JWTConfig.signer)
//        let payload = receivedJWT.payload
//
//        return payload.userID
//    } catch {
//        throw JWTError.verificationFailed
//    }
//}
