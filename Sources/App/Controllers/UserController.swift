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
        group.post(RefreshTokenRequest.self, at: "/refresh-token", use: refreshToken)
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
                        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                        let refreshToken = String((0 ... 40).map { _ in letters.randomElement()! })
                        let accessTokenResponse = AccessTokenResponse(refreshToken: refreshToken, accessToken: token, expiredAt: receivedJWT.payload.expirationAt.value)
                        
                        return RefreshToken(token: refreshToken, userID: try persistedUser.requireID()).save(on: req).transform(to: accessTokenResponse)
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
    
    func refreshToken(_ req: Request, refreshTokenDto: RefreshTokenRequest) throws -> Future<AccessTokenResponse> {
        let refreshTokenModel = RefreshToken.query(on: req).filter(\.token == refreshTokenDto.refreshToken).first().unwrap(or: Abort(.unauthorized))
        
        return refreshTokenModel.flatMap { refreshTokenModel in
            if refreshTokenModel.expiredAt > Date() {
                return refreshTokenModel.user.get(on: req).flatMap { user in
                    if let id = user.id {
                        let payload = AccessTokenPayload(userID: id)
                        let header = JWTConfig.header
                        let signer = JWTConfig.signer
                        let jwt = JWT<AccessTokenPayload>(header: header, payload: payload)
                        let tokenData = try signer.sign(jwt)
                        if let token = String(data: tokenData, encoding: .utf8) {
                            let receivedJWT = try JWT<AccessTokenPayload>(from: token, verifiedUsing: JWTConfig.signer)
                            let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                            let refreshToken = String((0 ... 40).map { _ in letters.randomElement()! })
                            refreshTokenModel.token = refreshToken
                            refreshTokenModel.updateExpiredDate()
                            let accessTokenResponse = AccessTokenResponse(refreshToken: refreshToken, accessToken: token, expiredAt: receivedJWT.payload.expirationAt.value)
                            
                            return refreshTokenModel.save(on: req).transform(to: accessTokenResponse)
                        } else {
                            throw JWTError.createJWT
                        }
                    } else {
                        throw JWTError.payloadCreation
                    }
                }
            } else {
                return refreshTokenModel.delete(on: req).thenThrowing {
                    throw Abort(.unauthorized)
                }
            }
        }
    }
}
