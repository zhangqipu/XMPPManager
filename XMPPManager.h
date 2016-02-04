//
//  XMPPManager.h
//  XMPPTest
//
//  Created by zhangqipu on 15/5/1.
//  Copyright (c) 2015年 zhangqipu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"

#define kHostName   (@"openfire.baoluo.dev")
#define kServerName (@"127.0.0.1")
#define kHostPort   (5222)

#define PRETTY_LOG(s) NSLog(@"---------------------------------------------\n%@\n---------------------------------------------", s);

@interface XMPPManager : NSObject <XMPPStreamDelegate, XMPPRosterDelegate>

// 是登陆还是注册
@property (assign, nonatomic) BOOL isLogin;

@property (copy, nonatomic) NSString *userName;
@property (copy, nonatomic) NSString *userPassword;

@property (strong, nonatomic) XMPPStream *xmppStream;
@property (strong, nonatomic) XMPPRoster *xmppRoster;
@property (strong, nonatomic) XMPPRosterCoreDataStorage *rosterStorage;

/**
 *  XMPP 单例
 *
 *  @return xmppManager
 */
+ (XMPPManager *)sharedXMPPManager;

/**
 *  连接服务器
 *
 *  @return YES - 连接成功
 */
- (BOOL)connectToHost;

/**
 *  登陆
 */
- (void)loginUser;

/**
 *  退出登录
 */
- (void)logoutUser;

/**
 *  注册
 */
- (void)registUser;
/**
 *  上线
 */
- (void)goOnLine;

/**
 *  下线
 */
- (void)goOffLine;

/**
 *  添加朋友
 */
- (void)addFriend;

/**
 *  发送消息
 */
- (void)sendMessageWithText:(NSString *)text;

@end
