//
//  AsyncURLConnection.h
//  rdicom
//
//  Created by tadasuke tsumura on 2013/11/18.
//  Copyright (c) 2013年 TRIART inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// *** 完了処理ブロック ***
typedef void (^completeBlock_t)(id conn, NSData *data);

// *** 進捗処理ブロック ***
typedef void (^progressBlock_t)(id conn, NSDictionary *dict);

// *** エラー処理ブロック ***
typedef void (^errorBlock_t)(id conn, NSError *error);

// ステータスコードエラー
extern NSString *const RESPONSE_CODE_ERROR;

// ==============================================
//
//  非同期URL通信オブジェクト
//
// ==============================================
@interface AsyncURLConnection : NSObject

@property (nonatomic, retain)   NSMutableData     *data;
@property (nonatomic, copy)     completeBlock_t   completeBlock;
@property (nonatomic, copy)     progressBlock_t   progressBlock;
@property (nonatomic, copy)     errorBlock_t      errorBlock;
@property (nonatomic, retain)   NSHTTPURLResponse *response;
@property (nonatomic, retain)   NSURLRequest      *request;
@property (nonatomic, retain)   NSURLConnection   *connection;
@property (nonatomic)           CGFloat           timeoutSec;

// --- リクエストの初期化 ---
-(id)initWithRequest:(NSURLRequest *)req
          timeoutSec:(CGFloat)sec
       completeBlock:(completeBlock_t)c_block
       progressBlock:(progressBlock_t)p_block
          errorBlock:(errorBlock_t)e_block;

// --- リクエストの実行 ---
-(void)performRequest;

// --- リクエストのキャンセル ---
-(void)cancel;

// --- 処理の完了を待つ ---
-(void)join;

@end
