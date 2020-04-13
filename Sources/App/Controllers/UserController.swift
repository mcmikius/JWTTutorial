//
//  UserController.swift
//  App
//
//  Created by Mykhailo Bondarenko on 13.04.2020.
//

import Vapor
import Crypto
import FluentSQLite
import JWT

final class UserController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("v1/account")
        
        group.post(User.self, at: "/sign-up", use: signUp)
        group.post(User.self, at: "/sign-in", use: signIn)
    }
    
    func signUp(_ req: Request, user: User) throws -> Future<MessageResponse> {
        return User.query(on: req).filter(\.login == user.login).first().flatMap { existingUser in
            guard existingUser == nil else {
                throw Abort(.badRequest, reason: "A user with login \(user.login) already exists")
            }
            let hashedPassword = try BCrypt.hash(user.password)
            let persistedUser = User(login: user.login, password: hashedPassword)
            
            return persistedUser.save(on: req).transform(to: MessageResponse(message: "Account created successfully"))
        }
    }
    
    func signIn(_ req: Request, user: User) throws -> Future<AccessTokenResponse> {
        return User.query(on: req).filter(\.login == user.login).first().unwrap(or: Abort(.badRequest, reason: "User with login \(user.login) not found")).flatMap { persistedUser in
            let digest = try req.make(BCryptDigest.self)
            if try digest.verify(user.password, created: persistedUser.password) {
                if let id = persistedUser.id {
                    let payload = AccessTokenPayload(userID: id)
                    let header = JWTConfig.header
                    let signer = JWTConfig.signer
                    let jwt = JWT<AccessTokenPayload>(header: header, payload: payload)
                    let tokenData = try signer.sign(jwt)
                    if let token = String(data: tokenData, encoding: .utf8) {
                        let receivedJWT = try JWT<AccessTokenPayload>(from: token, verifiedUsing: JWTConfig.signer)
                        let accessTokenResponse = AccessTokenResponse(accessToken: token, expiredAt: receivedJWT.payload.expirationAt.value)
                        return req.future(accessTokenResponse)
                    } else {
                        throw JWTError.createJWT
                    }
                } else {
                    throw JWTError.payloadCreation
                }
            } else {
                throw Abort(.badRequest, reason: "Incorrect user password")
            }
        }
    }
}
