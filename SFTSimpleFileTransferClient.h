//
//  SFTSimpleFileTransferClient.h
//  SimpleFileTransfer
//
//  Created by Nicolò Tosi on 9/9/13.
//  Copyright (c) 2013 MobFarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GCDAsyncSocket.h>

@class SFTSimpleFileTransferClient;

@protocol SFTSimpleFileTransferClientDelegate <NSObject>

-(void)clientDidCompleteTransfer:(SFTSimpleFileTransferClient *)client success:(BOOL)successOrFail;
-(void)client:(SFTSimpleFileTransferClient *)client couldNotConnectToAddress:(NSString *)address port:(int)port;
@end

@interface SFTSimpleFileTransferClient : NSObject <GCDAsyncSocketDelegate>

-(void)connectToAddress:(NSString *)address port:(int)port;
-(void)sendData:(NSData *)data;
-(void)sendData:(NSData *)data fileName:(NSString *)fileName;

@property (weak, nonatomic) id<SFTSimpleFileTransferClientDelegate>delegate;

@property (copy, nonatomic) void (^completionBlock)(BOOL);

@end
