import Vapor
import FluentSQLite

/// Controls basic CRUD operations on `Todo`s.
final class TodoController: RouteCollection {
    
    func boot(router: Router) throws {
        let group = router.grouped("v1/todo").grouped(JWTMiddleware())
        group.get(use: fetch)
        group.post(TodoRequest.self, use: create)
        group.delete(Int.parameter, use: delete)
    }
    
    /// Returns a list of all `Todo`s.
    func fetch(_ req: Request) throws -> Future<[TodoResponse]> {
        return try req.authorizedUser().flatMap { user in
            return try user.todos.query(on: req).all().flatMap { todos in
                return req.future(try todos.map { TodoResponse(id: try $0.requireID(), title: $0.title) })
            }
        }
    }
    
    /// Saves a decoded `Todo` to the database.
    func create(_ req: Request, todoRequest: TodoRequest) throws -> Future<TodoResponse> {
        return try req.authorizedUser().flatMap { user in
            return Todo(title: todoRequest.title, userID: try user.requireID()).save(on: req).flatMap { todo in
                return req.future(TodoResponse(id: try todo.requireID(), title: todo.title))
            }
        }
    }
    
    /// Deletes a parameterized `Todo`.
    func delete(_ req: Request) throws -> Future<TodoResponse> {
        let todoID = try req.parameters.next(Int.self)
        return try req.authorizedUser().flatMap { user in
            return try user.todos.query(on: req).filter(\.id == todoID).first().unwrap(or: Abort(.badRequest, reason: "User don't have todo with id \(todoID)")).delete(on: req).flatMap { todo in
                return req.future(TodoResponse(id: try todo.requireID(), title: todo.title))
            }
        }
    }
}
