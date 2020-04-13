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
        
        if let token = req.http.headers[.authorization].first {
            do {
                try JWT<AccessTokenPayload>(from: token, verifiedUsing: JWTConfig.signer)
                return try next.respond(to: req)
            } catch let error as JWTError {
                throw Abort(.unauthorized, reason: error.reason)
            }
        } else {
            throw Abort(.unauthorized, reason: "No Access Token")
        }
    }
}

