//
//  AccessTokenResponse.swift
//  App
//
//  Created by Mykhailo Bondarenko on 13.04.2020.
//

import Vapor

struct AccessTokenResponse: Content {
    let refreshToken: String
    let accessToken: String
    let expiredAt: Date
}
