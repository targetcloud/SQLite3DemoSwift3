//
//  ViewController.swift
//  SQLite3Demo
//
//  Created by targetcloud on 2016/12/7.
//  Copyright © 2016年 targetcloud. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var timeLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let userArr = User.allUserFromDB()
        print(userArr)
        timeLabel.text = "你查询到了 \(userArr!.count) 条记录"
    }

    //事务测试1
    @IBAction func transaction(){
        SQLite3Tool.shareInstance.beginTransaction()
        User.deleteUser("刘能")
        User.deleteUser("赵四")
        let user1 = User(name: "刘能", age:22, score: 100)
        let user2 = User(name: "赵四",age:33, score: 100)
        user1.insert()
        user2.insert2()
        let result1 = User.update("update t_user set money = money - 10 where name = '刘能'")
        let result2 = User.update("update t_user set money = money + 10 where name = '赵四'")
        if result1 && result2 {
            SQLite3Tool.shareInstance.commitTransaction()
        }else {
            SQLite3Tool.shareInstance.rollbackTransaction()
        }
    }
    
    //事务测试2
    @IBAction func transaction2(){
        SQLite3Tool.shareInstance.beginTransaction()
        User.deleteUser("铁娃")
        User.deleteUser("牛娃")
        let user1 = User(name: "铁娃", age:8, score: 60)
        let user2 = User(name: "牛娃",age:9, score: 50)
        user1.insertUser()
        user2.insert()
        let result1 = User.updateRecord("score = score - 10", condition: "name = '铁娃'")
        let result2 = User.updateRecord("score1 = score + 10", condition: "name = '牛娃'")//注意这里会失败，事务回滚了
        if result1 && result2{
            SQLite3Tool.shareInstance.commitTransaction()
        }else{
            SQLite3Tool.shareInstance.rollbackTransaction()
        }
    }
    
    //时间测试1 没开事务+sqlite3_exec
    @IBAction func timeTest(){
        let beginTime = CFAbsoluteTimeGetCurrent()
        let user = User(name: "时间测试1", age: 11, score: 11)
        for _ in 0..<10000 {
            user.insertUser()
        }
        let endTime = CFAbsoluteTimeGetCurrent()
        timeLabel.text = "没开事务+sqlite3_exec>\(endTime - beginTime)"
    }
    
    //时间测试2 没开事务+Stmt
    @IBAction func timeTest2(){
        let beginTime = CFAbsoluteTimeGetCurrent()
        let user = User(name: "时间测试2", age: 22, score: 22)
        for _ in 0..<10000 {
            user.bindInsertUser()
        }
        let endTime = CFAbsoluteTimeGetCurrent()
        timeLabel.text = "没开事务+Stmt>\(endTime - beginTime)"
    }
    
    //时间测试3 开事务
    @IBAction func timeTest3(){
        let beginTime = CFAbsoluteTimeGetCurrent()
        let user = User(name: "时间测试3", age: 33, score: 33)
        user.bindInsertUserWithTransaction(10000)
        let endTime = CFAbsoluteTimeGetCurrent()
        timeLabel.text = "开事务>\(endTime - beginTime)"
    }
    
    //时间测试4
    @IBAction func timeTest4(){
        let beginTime = CFAbsoluteTimeGetCurrent()
        let user = User(name: "时间测试4", age: 44, score: 44.43)
        User.insertBatch({() -> (Array<Array<Any>>) in
            var array = [[Any]]()//var array = Array<Array<Any>>()  //MARK:- 重点！性能最好
            for _ in 0...9999{
                array.append([user.name, user.score,user.age])
            }
            return array
        })
        let endTime = CFAbsoluteTimeGetCurrent()
        timeLabel.text = "开事务+Batch>\(endTime - beginTime)"
    }
    
    //查询测试1
    @IBAction func allQuery(){
        User.queryAll()
    }
    
    //查询测试2
    @IBAction func stmtQuery(){
        User.queryAllStmt()
    }

}

