//
//  JWTMiddleware.swift
//  App
//
//  Created by Mykhailo Bondarenko on 13.04.2020.
//

import Vapor
import JWT

public final class JWTMiddleware: Middleware {
    
    public func respond(to req: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        
        guard let bearer = req.http.headers.bearerAuthorization else {
            throw Abort(.unauthorized)
        }
        
        //        let jwt = try JWT<User>(from: bearer.token, verifiedUsing: .hs256(key: "secret"))
        _ = try JWT<AccessTokenPayload>(from: bearer.token, verifiedUsing: JWTConfig.signer)
        return try next.respond(to: req)
        
        //        return "Hello, \(jwt.payload.name)!"
        
        //        if let token = req.http.headers[.authorization].first {
        //            do {
        //
        //                try JWT<AccessTokenPayload>(from: token, verifiedUsing: JWTConfig.signer)
        //                return try next.respond(to: req)
        //            } catch let error as JWTError {
        //                throw Abort(.unauthorized, reason: error.reason)
        //            }
        //        } else {
        //            throw Abort(.unauthorized, reason: "No Access Token")
        //        }
    }
}

