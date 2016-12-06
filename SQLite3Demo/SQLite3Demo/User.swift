//
//  User.swift
//  SQLite3Demo
//
//  Created by targetcloud on 2016/12/7.
//  Copyright © 2016年 targetcloud. All rights reserved.
//

import UIKit

class User: NSObject {
    
    var name: String = ""
    var age: Int = 0
    var score: Float = 0.0
    var money: Float = 0.0
    
    init(name: String, age: Int, score: Float,money: Float = 100) {
        super.init()
        self.name = name
        self.age = age
        self.score = score
        self.money = money
    }
    
    init(dict : [String : Any]) {
        super.init()
        self.setValuesForKeys(dict)
    }
    
    class func allUserFromDB() -> [User]? {
        let sql = "SELECT name,age,score,money FROM t_User "
        let allUserDictArr = SQLite3Tool.shareInstance.queryAllStmt(sql)
        var userModelArrM = [User]()
        for dict in allUserDictArr {
            userModelArrM.append(User(dict: dict))
        }
        return userModelArrM
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
    }
    
    //辅助查询测试1
    class func queryAll() {
        SQLite3Tool.shareInstance.queryAll("select * from t_user")
    }
    
    //辅助查询测试2
    class func queryAllStmt() {
        SQLite3Tool.shareInstance.queryAllStmt("select * from t_user")
    }
    
    //辅助事务测试
    class func update(_ sql: String) -> Bool {
        return SQLite3Tool.shareInstance.execSQL(sql)
    }
    
    //辅助时间测试3
    func bindInsertUserWithTransaction(_ times:Int)  {
        let sql = "insert into t_user(name, age, score) values (?, ?, ?)"
        let db = SQLite3Tool.shareInstance.appdb
        var stmt: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) != SQLITE_OK {
            print("prepare fail")
            return
        }
        SQLite3Tool.shareInstance.beginTransaction()
        for i in 0..<times {
            sqlite3_bind_int(stmt, 2, Int32(i))//索引从1开始,age使用i
            sqlite3_bind_double(stmt, 3, Double(self.score))
            //            let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            sqlite3_bind_text(stmt, 1, self.name, -1, SQLite3Tool.shareInstance.SQLITE_TRANSIENT)
            if sqlite3_step(stmt) == SQLITE_DONE {
                print("step success")
            }
            sqlite3_reset(stmt)
        }
        SQLite3Tool.shareInstance.commitTransaction()
        sqlite3_finalize(stmt)
    }
    
    //辅助时间测试2
    func bindInsertUser()  {
        let sql = "insert into t_user(name, age, score) values (?, ?, ?)"
        let db = SQLite3Tool.shareInstance.appdb
        var stmt: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) != SQLITE_OK {
            print("prepare fail")
            return
        }
        sqlite3_bind_int(stmt, 2, Int32(self.age))
        sqlite3_bind_double(stmt, 3, Double(self.score))
        //        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(stmt, 1, self.name, -1, SQLite3Tool.shareInstance.SQLITE_TRANSIENT)
        if sqlite3_step(stmt) == SQLITE_DONE {
            print("step success")
        }
        sqlite3_reset(stmt)
        sqlite3_finalize(stmt)
    }
    
    //辅助时间测试1
    func insertUser()  {
        let sql = "insert into t_user(name, age, score) values ('\(self.name)', \(self.age), \(self.score))"
        if  SQLite3Tool.shareInstance.execSQL(sql)  {
            print("insert success")
        }
    }
    
    class func deleteUser(_ name: String)  {
        let sql = "delete from t_user where name = '\(name)'"
        if  SQLite3Tool.shareInstance.execSQL(sql)  {
            print("delete success")
        }
    }
    
    //插入方式2
    class func insertBatch(_ valuesBlock: @escaping () -> (Array<Array<Any>>)){
        SQLite3Tool.shareInstance.insertBatch("t_user", columnNameArray: ["name", "score","age"], valuesBlock: { () -> Array<Array<Any>> in
            return valuesBlock()
        })
    }
    
    //插入方式1
    func insert(){
        if  SQLite3Tool.shareInstance.insert("t_user", columnNameArray: ["name", "score","age"], valueArray: [self.name, self.score,self.age]){
            print("insert success")
        }
    }
    
    func insert2(){
        if  SQLite3Tool.shareInstance.insert("t_user", columnNameArray: ["name", "score","age"], values: self.name, self.score,self.age){
            print("insert2 success")
        }
    }
    
    //更新方式1 对象方法
    func updateUser(_ newUser: User)  {
        let sql = "update t_user set name = '\(newUser.name)', age = \(newUser.age), score = \(newUser.score) where name = '\(self.name)'"
        if  SQLite3Tool.shareInstance.execSQL(sql)  {
            print("update success")
        }
    }
    
    //更新方式2 类方法
    class func updateRecord(_ setStr: String, condition: String)-> Bool {
        return SQLite3Tool.shareInstance.updateRecord("t_user", setStr: setStr, condition: condition)
    }
    
}
