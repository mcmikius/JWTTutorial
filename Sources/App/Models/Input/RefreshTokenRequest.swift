//
//  RefreshTokenRequest.swift
//  App
//
//  Created by Mykhailo Bondarenko on 13.04.2020.
//

import Vapor

struct RefreshTokenRequest: Content {
    let refreshToken: String
}
