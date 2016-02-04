//
//  XMPPManager.m
//  XMPPTest
//
//  Created by zhangqipu on 15/5/1.
//  Copyright (c) 2015年 zhangqipu. All rights reserved.
//

/*
 1.初始化xmpp
 2.连接服务器
 3.身份认证
 4.登陆
 5.显示在线
 6.退出登录
 7.断开连接
 */

#import "XMPPManager.h"

@implementation XMPPManager

static XMPPManager *xmppManager = nil;

+ (XMPPManager *)sharedXMPPManager
{
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
       
        xmppManager = [[self alloc] init];
        
        // 设置 xmppStream
        [xmppManager setUpXmppStream];
    });
    
    return xmppManager;
}

/**
 *  设置xmppStream
 */
- (void)setUpXmppStream
{
    // 初始化
    self.xmppStream = [[XMPPStream alloc] init];
    
    // 设置代理
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // 设置连接服务器和端口
    [self.xmppStream setHostName:kHostName];
    [self.xmppStream setHostPort:kHostPort];
    
    self.rosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.rosterStorage];
    [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    self.xmppRoster.autoFetchRoster = YES;
    self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    [self.xmppRoster activate:self.xmppStream];
}

/**
 *  连接服务器
 *
 *  @return YES - 连接成功
 */
- (BOOL)connectToHost
{
    if (self.userName == nil || self.userPassword == nil)
        return NO;
    
    if ([self.xmppStream isDisconnected] == NO)
    {
        [self.xmppStream disconnect];
    }
    
    NSError *err = nil;
    XMPPJID *jid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@", self.userName, kServerName]];
    
    [self.xmppStream setMyJID:jid];
    
    if ([self.xmppStream connectWithTimeout:-1 error:&err] == NO)
    {
        PRETTY_LOG(err);
        return NO;
    }
    
    return YES;
}

/**
 *  登陆
 */
- (void)loginUser
{
    self.isLogin = YES;
    
    if ([self connectToHost] == NO)
    {
        PRETTY_LOG(@"连接服务器失败！");
        return ;
    }
}

/**
 *  退出登录
 */
- (void)logoutUser
{
    
}

/**
 *  注册
 */
- (void)registUser
{
    self.isLogin = NO;
    
    if ([self connectToHost] == NO)
    {
        PRETTY_LOG(@"连接服务器失败！");
        return ;
    }
}

/**
 *  上线
 */
- (void)goOnLine
{
    XMPPPresence *presence = [[XMPPPresence alloc] initWithType:@"available"];
    
    [self.xmppStream sendElement:presence];
    
    [self sendMessageWithText:@"Hell"];
}

/**
 *  下线
 */
- (void)goOffLine
{
    XMPPPresence *presence = [[XMPPPresence alloc] initWithType:@"unavailable"];
    
    [self.xmppStream sendElement:presence];
    [self.xmppStream disconnect];
}

/**
 *  添加朋友
 */
- (void)addFriend
{
    XMPPJID *jid = [XMPPJID jidWithUser:@"zhangqipu" domain:kServerName resource:nil];
    
    [self.xmppRoster subscribePresenceToUser:jid];
}

/**
 *  发送消息
 */
- (void)sendMessageWithText:(NSString *)text
{
    // 发给谁
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@", @"jj", kServerName]]];
    
    // 消息内容
    [message addChild:[DDXMLNode elementWithName:@"body" stringValue:@"{\"userid\":\"zhangqipu@127.0.0.1\",\"from\":\"IN\",\"type\":\"normal\",\"date\":\"05-29  09:53:28\",\"receive\":\"null\",\"msg\":\"hell world\n\"}"]];
    
    // 发送
    [self.xmppStream sendElement:message];
}

#pragma mark -
#pragma mark XMPPStream Delegate

/**
 *  连接服务器成功
 *
 *  @param sender
 */
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSError *err = nil;
    
    if (self.isLogin)
    {
        // 登陆
        if ([self.xmppStream authenticateWithPassword:self.userPassword error:&err] == NO)
        {
            PRETTY_LOG(err);
        }
    }
    else
    {
        // 注册
        if ([self.xmppStream registerWithPassword:self.userPassword error:nil] == NO)
        {
            PRETTY_LOG(err);
        }
    }
}

/**
 *  连接服务器超时
 *
 *  @param sender
 */
- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender
{

}

/**
 *  认证成功
 *
 *  @param sender
 */
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [self goOnLine];
}

/**
 *  认证失败
 *
 *  @param sender
 *  @param error  失败信息节点
 */
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error
{
    
}

/**
 *  注册成功
 *
 *  @param sender
 */
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    
}

/**
 *  注册失败
 *
 *  @param sender
 *  @param error  注册失败信息节点
 */
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error
{

}

#pragma mark -
#pragma mark Receive

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    PRETTY_LOG(iq);
    
    return YES;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    NSString *content = [[message elementForName:@"body"] stringValue];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessageNotification" object:content];
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    PRETTY_LOG(presence);
}

#pragma mark -
#pragma mark - Send

- (void)xmppStream:(XMPPStream *)sender didSendIQ:(XMPPIQ *)iq
{
    PRETTY_LOG(iq);
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    PRETTY_LOG(message);
}

- (void)xmppStream:(XMPPStream *)sender didSendPresence:(XMPPPresence *)presence
{
    PRETTY_LOG(presence);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendIQ:(XMPPIQ *)iq error:(NSError *)error
{
    PRETTY_LOG(error);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    PRETTY_LOG(error);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendPresence:(XMPPPresence *)presence error:(NSError *)error
{
    PRETTY_LOG(error);
}

#pragma mark -
#pragma mark XMPPRoster Delegate

/**
 *  收到添加好友请求
 *
 *  @param sender
 *  @param presence 请求信息节点
 */
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    //请求的用户
    NSString *presenceFromUser =[NSString stringWithFormat:@"%@", [[presence from] user]];
    XMPPJID *jid = [XMPPJID jidWithString:presenceFromUser];
    [self.xmppRoster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
}

@end
