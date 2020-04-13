//
//  UserController.swift
//  App
//
//  Created by Mykhailo Bondarenko on 13.04.2020.
//

import Vapor
import Crypto
import FluentSQLite

final class UserController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("v1/account")
        
        group.post(User.self, at: "/sign-up", use: signUp)
        group.post(User.self, at: "/sign-in", use: signIn)
    }
    
    func signUp(_ req: Request, user: User) throws -> Future<ResponseMessage> {
        return User.query(on: req).filter(\.login == user.login).first().flatMap { existingUser in
            guard existingUser == nil else {
                throw Abort(.badRequest, reason: "A user with login \(user.login) already exists")
            }
            let hashedPassword = try BCrypt.hash(user.password)
            let persistedUser = User(login: user.login, password: hashedPassword)

            return persistedUser.save(on: req).transform(to: ResponseMessage(message: "Account created successfully"))
        }
    }
    
    func signIn(_ request: Request, user: User) throws -> Future<HTTPResponseStatus> {
        return request.future(.notImplemented)
    }
}
