//
//  PaymentVerifyTask.swift
//  IAP_Swift
//
//  Created by 何玉龙 on 2019/11/7.
//  Copyright © 2019 com.BryantStudio. All rights reserved.
//

import UIKit
import CommonCrypto

// MARK: - ENUM PaymentVerifyTaskState
enum PaymentVerifyTaskState {
    case defaultInit // 初始化状态
    case waitingForServersResponse // 等待服务器响应
    case finished // 完成
    case cancel // 取消. 一旦取消, 这个 task 就不能再次调用 start 方法重新执行了
}

// MARK: - Portocol PaymentVerifyTaskPortocol
protocol PaymentVerifyTaskPortocol {
    
    /**
    * 验证收到结果通知, 验证收据有效.
    */
    func paymentVerifyTaskDidReceiveResponseReceiptValid(with task: PaymentVerifyTask, result: [String : AnyObject]?)
    
    /**
    * 验证收到结果通知, 验证收据无效.
    */
    func paymentVerifyTaskDidReceiveResponseReceiptInvalid(with task: PaymentVerifyTask)
    
    /**
    * 验证请求出现错误, 需要重新请求.
    */
    func paymentVerifyTaskUploadCertificateRequestFailed(with task: PaymentVerifyTask)
    
    /**
    * 创建订单请求成功.
    *
    * @param task           当前任务.
    * @param orderNo        订单号.
    * @param priceTagString 价格字符串.
    * @param md5            交易收据是否有变动的标识.
    */
    func paymentVerifyTaskDidReceiveCreateOrderResponse(with task: PaymentVerifyTask, orderNum: String, priceTagString: String, md5: String)
    
    /**
    * 创建订单请求出现错误, 需要重新请求.
    */
    func paymentVerifyTaskCreateOrderRequestFailed(with task: PaymentVerifyTask)
}


// MARK: - Class PaymentVerifyTask
class PaymentVerifyTask: NSObject {
    
    /**
    * Delegate.
    */
    var delegate: PaymentVerifyTaskPortocol?
    
    /**
    * 交易凭证验证模型.
    */
    private(set) var transactionModel: PaymentTransactionModel!
    
    /**
    * task 状态.
    */
    private(set) var taskState: PaymentVerifyTaskState
    
    /**
    * 收据.
    */
    private(set) var transactionReceiptData: NSData
    
    /**
    * 初始化方法.
    *
    * @warning 交易模型不能为空.
    *
    * @param paymentTransactionModel 交易模型.
    * @param transactionReceiptData  交易凭证.
    */
    init(model: PaymentTransactionModel!, receiptData: NSData!) {
        self.transactionModel = model
        self.transactionReceiptData = receiptData
        self.taskState = .defaultInit
    }
    
    /**
    * 开始执行当前 task.
    *
    * @warning task 一旦取消, 这个 task 就不能再次调用 -start 方法重新执行了.
    */
    func start() {
        if self.taskState == .cancel {
            print("尝试调起一个被取消的 task , 所以无效")
            return
        }
        
        let receipts = self.transactionReceiptData.base64EncodedString(options: .endLineWithLineFeed)
        if receipts.isEmpty {
            print("验证收据为空 crtf: \(receipts)")
            // todo 上报
        }
        
        // 如果有订单号和 md5 值, 并且 md5 值没有变动, 开始验证.
        // 如果没有创建订单的逻辑，则去掉，直接使用 uploadCertificateRequest() 方法
        let md5 = sha256(receipts)
        let needStartVerify = !self.transactionModel.orderNum!.isEmpty && !self.transactionModel.md5!.isEmpty && self.transactionModel.md5 == md5
        self.taskState = .waitingForServersResponse
        if needStartVerify {
            print("开始上传收据验证")
            uploadCertificateRequest()
        } else {
            print("开始创建订单")
        }
    }
    
    
    /**
    * 取消当前 task.
    *
    * @warning task 一旦取消, 这个 task 就不能再次调用 start 方法重新执行了.
    */
    func cancel() {
        self.taskState = .cancel
    }
    
    // MARK: - Network Request
    private func createOrderRequest(with productIdentifier: String, and md5: String) {
        // 执行创建订单请求.
    }
    
    private func uploadCertificateRequest() {
        // 发送上传凭证进行验证请求.
        let receipts = self.transactionReceiptData.base64EncodedString(options: .endLineWithLineFeed)
        let md5 = sha256(receipts)
        
        // todo 上传到自己的服务器去验证
    }
    
    
    // MARK: - Request Result Handler
    // todo 验证接口的成功回调里调用
    private func handleVerifingTransactionValid(resultDict: [String : AnyObject]) {
        print("订单验证成功, Valid")
        self.delegate?.paymentVerifyTaskDidReceiveResponseReceiptValid(with: self, result: resultDict)
    }
    
    // todo 验证接口的错误回调里调用
    private func handleVerifingTransactionInvalidWithErrorMessage(errorMessage: String) {
        print("订单已验证：无效，Invalid")
        self.delegate?.paymentVerifyTaskDidReceiveResponseReceiptInvalid(with: self)
    }
    
    // todo 验证接口没有被调用的情况下
    private func handleUploadCertificateRequestFailed() {
        print("网络不佳，订单验证失败。传入验证队列，再次验证")
        self.delegate?.paymentVerifyTaskUploadCertificateRequestFailed(with: self)
    }
    
    // 创建订单成功
    private func handleCreateOrderSuccessed(orderNum: String, priceTagString: String, md5: String) {
        print("创建订单成功")
        self.delegate?.paymentVerifyTaskDidReceiveCreateOrderResponse(with: self, orderNum: orderNum, priceTagString: priceTagString, md5: md5)
    }
    
    // 创建订单失败
    private func handleCreateOrderFailed() {
        print("创建订单失败")
        self.delegate?.paymentVerifyTaskCreateOrderRequestFailed(with: self)
    }
    
    
    // MARK: - Private Method
    override func isEqual(_ object: Any?) -> Bool {
        if object == nil {
            return false
        }
        
        if self == object as! PaymentVerifyTask {
            return true
        }
        
        if !(object is PaymentVerifyTask) {
            return false
        }
        
        return isEqual(to: object as! PaymentVerifyTask)
    }
    
    private func isEqual(to task: PaymentVerifyTask) -> Bool{
        var isTransactionIdentifierMatch = false
        var isProductIdentifierMatch = false
        if self.transactionModel.transactionIdentifier == task.transactionModel.transactionIdentifier {
            isTransactionIdentifierMatch = true
        }
        if self.transactionModel.productIdentifier == task.transactionModel.productIdentifier {
            isProductIdentifierMatch = true
        }
        return isTransactionIdentifierMatch && isProductIdentifierMatch
    }
    
    private func sha256(_ data: Data) -> Data? {
        guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else { return nil }
        CC_SHA256((data as NSData).bytes, CC_LONG(data.count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
        return res as Data
    }
    
    private func sha256(_ str: String) -> String? {
        guard
            let data = str.data(using: String.Encoding.utf8),
            let shaData = sha256(data)
            else { return nil }
        let rc = shaData.base64EncodedString(options: [])
        return rc
    }
    
    override var description: String {
        var taskStateString = ""
        switch self.taskState {
            case .defaultInit:
                taskStateString = "defaultInit"
            case .waitingForServersResponse:
                taskStateString = "waitingForServersResponse"
            case .finished:
                taskStateString = "finished"
            case .cancel:
                taskStateString = "cancel"
        }
        return "delegate: \(String(describing: self.delegate)), transactionModel: \(String(describing: self.transactionModel)), taskState: \(taskStateString)"
    }
}




