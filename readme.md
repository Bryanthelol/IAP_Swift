# in-app-purchase IAP Swift

IAP库的Swift版本

## 核心思想

问题：

苹果通知交易结果一个生命周期只通知一次

解决思路：

首先一旦苹果通知我们交易成功，我们就要将交易数据自己存起来。存哪里？存keychain。

keychain 的特点就是：

* 第一安全；
* 第二，绑定 APP ID，不会丢，永远不会丢，卸载 APP 以后重装，仍然能从 keychain 里恢复之前的数据。

## 组成部分

* 订单存储模块
  * 订单Model
    * 实现encode协议，可以data化
    * 实现isEqual方法，比较对象细节
  * 存储工具，基于keychain
  * 订单Model归档成NSData
  * 多个Data组成一个set
  * 再将这个set归档
  * 把归档后的set保存在字典中，key为userid
  * 再把字典归档，保存在keychain中
* 验证队列模块
  * 5个入口：
    1. app初始化
    2. 新交易
    3. 连接网络
    4. 进入前台
    5. 单个task验证完毕
  * 除第五个入口外，从其余入口进入后，去keychain查看
    * 根据task优先级，动态筛选task进入验证队列
      * 向服务器发起的验证，不一定成功，如果失败了，我们就要给这个交易模型打上一个标记
      * 下次验证的时候，应该优先验证那些没有被打上标记的交易模型
      * 如果不打标记，可能会出现一直在验证同一个交易模型，阻塞了其他交易模型的验证
  * 存入keychain的时机
    * app初始化
      * 去 IAP 的交易队列里检查一遍，如果有没有被持久化到 keyChain 的，就直接压入 keyChain 中进行持久化
    * 新交易
    * 进入前台
      * 用户从后台进入前台的时候，也会去检查一遍沙盒中有没有没有持久化的交易，一旦有，就把这些交易压入 keyChain 中

## 项目结构

* PaymentManager类，交易管理者
  * 一个单例，验证队列挂在它身上
  * 负责和 IAP 通讯，包括商品查询和购买功能
  * 交易状态的监听者
  * 对接沙盒中收据数据的获取和更新
  * 整个支付的入口
  * PaymentManager类会把交易丢给PaymentVerifyManager类
* PaymentVerifyManager类
  * 验证交易队列管理者
    * 内部有一个需要验证的交易 task 队列
    * 它负责管理这些队列的状态，并且驱动这些任务的执行，保证每笔交易验证的先后循序  
    * 内部还有一个keyChain
    * 队列中的任务都是从 keyChain 中初始化过来的
    * 同时它也管理着keyChain 中的数据，对keyChain 进行增删改查等操作，维护keyChain 的状态
    * PaymentVerifyManager类验证后，会和PaymentManager类通信
    * 告诉 PaymentManager 某笔交易的状态，让PaymentManager处理掉指定的交易
* PaymentVerifyTask类
  * 负责和服务器通讯，并且将通讯结果回调出来给 PaymentVerifyManager，驱动下一个验证操作
* keyChain 提供交易数据的持久化
