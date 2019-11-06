//
//  PaymentTransactionModel.swift
//  IAP_Swift
//
//  Created by 何玉龙 on 2019/11/3.
//  Copyright © 2019 com.BryantStudio. All rights reserved.
//

import UIKit

class PaymentTransactionModel: NSObject, NSCoding {
    
    /**
    * 商品 id.
    */
    let productIdentifier: String!
    
    /**
    * 事务 id.
    */
    let transactionIdentifier: String!
    
    /**
    * 交易时间(添加到交易队列时的时间).
    */
    let transactionDate: NSDate!

    /**
    * 后台配置的订单号.
    */
    var orderNum: String?
    
    /**
    * 价格字符.
    */
    var priceTagString: String?
    
    /**
    * 交易收据是否有变动的标识.
    */
    var md5: String?
    
    /*
    * 任务被验证的次数.
    * 初始状态为 0,从未和后台验证过.
    * 当次数大于 1 时, 至少和后台验证过一次，并且未能验证当前交易的状态.
    */
    var modelVerifiedCount: Int {
        willSet {
            if newValue > Constants.paymentTransactionModelVerifyWarningCount {
                // todo report to server side.
                assertionFailure("验证次数超过最大验证次数: \(Constants.paymentTransactionModelVerifyWarningCount)")
            }
        }
    }
    
    /**
    * 是否已经在后台验证过并且有了结果(成功或者失败).
    *
    * @warning: 1. 确实会出现明明有未成功的交易, 但是在苹果的未完成交易列表里取不到. 此时应该将这笔订单的状态更改过来.
    *           2. 这个值默认是 NO, 代表没有在后台验证过, 直到在后台验证过, 然后去 IAP 未完成交易列表中取值的取不到这笔订单的时候才会将订单的状态改为 YES.
    *           3. 对于验证有结果并且能在 IAP 的未完成交易中取到值的交易, 直接就会从 keychain 中删除.
    */
    var isTransactionValidFromService: Bool
    
    /**
    * 初始化方法(没有收据的).
    *
    * @warning: 所有数据都必须有值, 否则会报错, 并返回 nil.
    *
    * @param productIdentifier       商品 id.
    * @param transactionIdentifier   事务 id.
    * @param transactionDate         交易时间(添加到交易队列时的时间).
    */
    init(productIdentifier: String!, transactionIdentifier: String!, transactionDate: NSDate!) {
        self.productIdentifier = productIdentifier
        self.transactionIdentifier = transactionIdentifier
        self.transactionDate = transactionDate
        self.modelVerifiedCount = 0
        self.isTransactionValidFromService = false
    }
    
    
    func encode(with coder: NSCoder) {
        coder.encode(self.productIdentifier, forKey: "productIdentifier")
        coder.encode(self.transactionIdentifier, forKey: "transactionIdentifier")
        coder.encode(self.transactionDate, forKey: "transactionDate")
        coder.encode(self.modelVerifiedCount, forKey: "modelVerifiedCount")
        coder.encode(self.isTransactionValidFromService, forKey: "isTransactionValidFromService")
        
        // optional
        coder.encode(self.orderNum, forKey: "orderNum")
        coder.encode(self.priceTagString, forKey: "priceTagString")
        coder.encode(self.md5, forKey: "md5")
    }
    
    required init?(coder: NSCoder) {
        self.productIdentifier = (coder.decodeObject(forKey: "productIdentifier") as! String)
        self.transactionIdentifier = (coder.decodeObject(forKey: "transactionIdentifier") as! String)
        self.transactionDate = (coder.decodeObject(forKey: "transactionDate") as! NSDate)
        self.modelVerifiedCount = coder.decodeInteger(forKey: "modelVerifiedCount")
        self.isTransactionValidFromService = coder.decodeBool(forKey: "isTransactionValidFromService")
        
        // optional
        self.orderNum = coder.decodeObject(forKey: "orderNum") as? String
        self.priceTagString = coder.decodeObject(forKey: "priceTagString") as? String
        self.md5 = coder.decodeObject(forKey: "md5") as? String
    }
    
    
    // MARK: - Private Method
    // test todo
    override func isEqual(_ object: Any?) -> Bool {
        if object == nil {
            return false
        }
        if self == object as! PaymentTransactionModel {
            return true
        }
        if !(object is PaymentTransactionModel) {
            return false
        }
        return isEqual(toSelf: object as! PaymentTransactionModel)
    }
    
    // test todo
    private func isEqual(toSelf model: PaymentTransactionModel) -> Bool {
        var isProductIdentifierMatch = false
        var isTransactionIdentifierMatch = false
        var isMd5Match = false
        
        if self.productIdentifier == model.productIdentifier {
            isProductIdentifierMatch = true
        }
        if self.transactionIdentifier == model.transactionIdentifier {
            isTransactionIdentifierMatch = true
        }
        if self.md5 == nil && model.md5 == nil {
            isMd5Match = true
        } else {
            isMd5Match = self.md5 == model.md5 ? true : false
        }
        return isProductIdentifierMatch && isTransactionIdentifierMatch && isMd5Match
    }
}
