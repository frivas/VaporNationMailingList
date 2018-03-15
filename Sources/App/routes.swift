import Routing
import Vapor
import Foundation
import Crypto
import Dispatch
import Mailgun

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router) throws {
    router.get("hello") { (req) in
        return "Hello World"
    }
    
    router.get("mail") { (req) -> Future<Response> in
        let content: MailgunFormData = MailgunFormData(
            from: "postmaster@twof.me",
            to: "fabiobean2@gmail.com",
            subject: "Newsletter",
            text: "This is a newsletter"
        )
        
        let mailgunClient = try req.make(MailgunEngine.self)
        return try mailgunClient.sendMail(data: content, on: req)
    }
    
    router.post("mass_mail") { (req) -> Future<HTTPStatus> in
        let mailgunClient = try req.make(MailgunEngine.self)
        
        return User.query(on: req).all().flatMap(to: HTTPStatus.self) { (users) in
            var mailgunFutures: [Future<Response>] = []
            
            for user in users {
                let content: MailgunFormData = MailgunFormData(
                    from: "postmaster@twof.me",
                    to: user.email,
                    subject: "Newsletter",
                    text: "Hello \(user.name)! This is a newsletter"
                )
                
                let mailgunRequest = try mailgunClient.sendMail(data: content, on: req)
                mailgunFutures.append(mailgunRequest)
            }
            
            return mailgunFutures.flatten().map(to: [Response].self) { (responses) in
                print(responses)
                return responses
            }.transform(to: HTTPStatus.ok)
        }
    }
    
    router.get("user") { (req) -> Future<[User]> in
        return User.query(on: req).all()
    }
    
    router.post(User.self, at: "user") { (req, newUser: User) -> Future<User> in
        return newUser.save(on: req)
    }
}

extension Data {
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}

