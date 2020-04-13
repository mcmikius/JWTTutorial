//
//  TodoRequest.swift
//  App
//
//  Created by Mykhailo Bondarenko on 13.04.2020.
//

import Vapor

struct TodoRequest: Content {
    
    let id: Int?
    let title: String
}
