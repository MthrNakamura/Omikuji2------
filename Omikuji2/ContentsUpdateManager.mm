//
//  ContentsUpdateManager.m
//  Welcome抽選会
//
//  Created by tadasuke tsumura on 2013/11/27.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#include "ContentsUpdateManager.hpp"
#include "AsyncURLConnection.h"

#include "MBProgressHUD.h"
#include "AppDelegate.h"

#include "TopViewController.h"

// ===============================================
//
//  コンテンツ更新マネージャの実装
//
// ===============================================
namespace ContentsUpdateManager {
    
    // 最終更新日時タグ名
    static NSString *const KEY_FINALUPDATE_DATE = @"finalUpdDatetime";
    
    
    // *** コンテンツリスト関連 ***
    
    // --- コンテンツリストの取得 ---
    NSDictionary* getContentsList(UIViewController *vc, AlertUtil::ALERT_TYPE &atype);
    
    // --- ローカルに保存しているコンテンツリストの取得 ---
    NSMutableDictionary *getLocalContentsList();
    
    // --- コンテンツリストのローカル保存 ---
    void saveContentsList(NSMutableDictionary* contents_list);
    
    // --- ローカル保存用コンテンツリストの生成 ---
    NSMutableDictionary *createLocalContentsList(NSMutableArray* contents_list);
    
    // --- コンテンツリストへの新規オブジェクトの追加 ---
    void addContent2List(NSDictionary* content, NSString* content_id, NSMutableDictionary* contents_list);
    
    
    // *** コンテンツダウンロード関連 ***
    
    // --- コンテンツのアップデート ---
    bool downloadContentsShouldBeUpdated(UIViewController *vc, NSMutableArray* contents_list, AlertUtil::ALERT_TYPE &type);
    
    // --- 全コンテンツの取得 ---
    bool downloadAllContents(NSMutableArray* contents_list, AlertUtil::ALERT_TYPE &atype);
    
    // --- 指定コンテンツのデータダウンロード ---
    bool downloadContent(NSDictionary* contents, NSString* content_id, bool download, AlertUtil::ALERT_TYPE &atype);
    
    // --- マルチメディアデータのダウンロード ---
    bool downloadMultimediaData(NSString* content_id, AlertUtil::ALERT_TYPE &atype);
}

// ***********************************************
// * コンテンツのアップデート
// ***********************************************
void ContentsUpdateManager::update(UIViewController *vc,
                                   bool goto_toppage,
                                   std::function<void(ContentsUpdateManager::STATE)> progress_func,
                                   std::function<void(AlertUtil::ALERT_TYPE,ContentsUpdateManager::STATE)> error_func)
{
    AlertUtil::ALERT_TYPE atype;
    
    // **************** リストの取得処理 *****************
    
    NSLog( @"get list" );
    
    // コンテンツリストの取得
    auto contents_list = getContentsList( vc, atype );
    
    // コンテンツリストの取得に失敗
    if ( !contents_list ) {
        // エラー関数の実行
        if ( error_func ) error_func( atype, ContentsUpdateManager::START_GETLIST );
        return;
    }
    
    NSLog( @"complete list" );
    
    // 進捗状況の通知
    if ( progress_func ) progress_func( ContentsUpdateManager::COMPLETE_GETLIST );
    
    // **************** コンテンツの更新処理 *****************
    
    // コンテンツの更新
    bool success = downloadContentsShouldBeUpdated(  vc, [contents_list objectForKey:
                                                     CONTENTSLIST_KEY],
                                                     atype );
    
    NSLog( @"complete update" );
    
    // コンテンツの更新に失敗
    if ( !success ) {
        if ( error_func ) error_func( atype, ContentsUpdateManager::COMPLETE_GETLIST );
        return;
    }
    
    // 進捗状況の通知
    if ( progress_func ) progress_func( ContentsUpdateManager::COMPLETE_UPDATE );

    // **************** 後処理 *****************
    
    // トップページに遷移するとき
    if ( goto_toppage ) {
        TopViewController *topView = [vc.storyboard instantiateViewControllerWithIdentifier:@"TopView"];
        [vc presentViewController:topView animated:YES completion:nil];
    }
}

// +++++++++++++++++++++++++++++++++++++++++++++++
//
//  コンテンツリスト関連
//
// +++++++++++++++++++++++++++++++++++++++++++++++

// ***********************************************
// * コンテンツリストの取得
// ***********************************************
NSDictionary* ContentsUpdateManager::getContentsList(UIViewController *vc, AlertUtil::ALERT_TYPE &atype) {
    
    // リクエストの生成
    auto request = ConnectionUtil::createRequest( LIST_API, true, nil );
    
    atype = AlertUtil::ALERT_NONE;
    
    // *** プログレスバーの表示 ***
    auto progress = [[MBProgressHUD alloc] initWithView:vc.view];
    progress.labelText = @"リスト取得中";
    [vc.view addSubview:progress];
    [progress show:YES];
    
    // 通信オブエジェクとの生成
    auto conn = [[AsyncURLConnection alloc] initWithRequest:request
                                                timeoutSec:TIMEOUT_INTERVAL
    
    // 通信完了時
    completeBlock:^(AsyncURLConnection *conn, NSData *data) {
    
        ConnectionUtil::HTTP_CODE code;
        
        // コンテンツリストの保持
        APP_DEL.contentsList = ConnectionUtil::checkAndSerializeResponse( conn.response,
                                                          data, code );
       
        // アラートタイプの取得
        atype = AlertUtil::convert( code, false );
        
        // プログレスバーの非表示
        [progress hide:YES];
        [progress removeFromSuperview];
    }
    progressBlock:nil

    // エラー発生時
    errorBlock:^(AsyncURLConnection *conn, NSError *error) {
    
        // プログレスバーの非表示
        [progress hide:YES];
        [progress removeFromSuperview];
        
        atype = ( error.code==NSURLErrorTimedOut ) ? AlertUtil::TIMEDOUT
                                                   : AlertUtil::NETWORK_ERROR;
    } ];
    
    // 同期通信の実行
    [conn performRequest];
    [conn join];
    
    // 何かしら問題があった場合は nil を返す
    return ( atype==AlertUtil::ALERT_NONE ) ? APP_DEL.contentsList : nil;
}

// ***********************************************
// * ローカルに保存しているコンテンツリストの取得
// ***********************************************
NSMutableDictionary* ContentsUpdateManager::getLocalContentsList() {
    
    // プリファレンスからローカルリストを取得する
    auto defaults = [NSUserDefaults standardUserDefaults];
    auto pref_data = [defaults dataForKey:CONTENTSLIST_KEY];
    
    return ( pref_data ) ? [NSKeyedUnarchiver unarchiveObjectWithData:pref_data]
                         : nil;
}

// ***********************************************
// * コンテンツリストのローカル保存
// ***********************************************
void ContentsUpdateManager::saveContentsList(NSMutableDictionary* contents_list) {
    
    // コンテンツリストの保存
    auto defaults = [NSUserDefaults standardUserDefaults];
    auto pref_data = [NSKeyedArchiver archivedDataWithRootObject:contents_list];
    [defaults setObject:pref_data forKey:CONTENTSLIST_KEY];
}

// ***********************************************
// * ローカル保存用コンテンツリストの生成
// ***********************************************
NSMutableDictionary* ContentsUpdateManager::createLocalContentsList(NSMutableArray* contents_list)
{
    auto local_list = [[NSMutableDictionary alloc] init];
    
    for ( NSDictionary *content in contents_list ) {
        
        // 指定コンテンツ情報の追加
        addContent2List( content,
                         [content objectForKey:@"id"],
                         local_list );
    }
    
    return local_list;
}

// ***********************************************
// * コンテンツリストへの新規オブジェクトの追加
// ***********************************************
void ContentsUpdateManager::addContent2List(NSDictionary* content, NSString* content_id, NSMutableDictionary* contents_list)
{
    NSDictionary *new_content = nil;
    
    // コンテンツタイプの取得
    int type = [[content objectForKey:@"type"] intValue];
    
    switch ( type ) {
            
        case CONTENTS_TOPURL: //TOP画面
        case CONTENTS_QR_RAYER: //QR読み取り画面
        case ERROR_DRAWEROPENED: //印刷エラー(カバーが開いている)
        case ERROR_FAILEDTOCUT: //紙のカットに失敗
        case ERROR_HEADERTEMP: //ヘッダーの温度が異常
        case ERROR_PAPEREMPTY: //紙切れ
        case ERROR_PAPERJAMMED: //紙詰まり
        case ERROR_POWERERROR: //電源異常
        case ERROR_UNUSUALDATA: //異常な量のデータを受け取った
        case ERROR_PAIRING:     //BLuetoothペアリング
            
            new_content = [[NSDictionary alloc]
                           initWithObjectsAndKeys:[content objectForKey:@"type"], @"type", [content objectForKey:@"url"], @"url",
                           [NSNumber numberWithLongLong:[[content objectForKey:KEY_FINALUPDATE_DATE] longLongValue]], KEY_FINALUPDATE_DATE, nil];
            break;
            
        case CONTENTS_MOVIE: //動画
        case CONTENTS_SOUND: //サウンド
            
            new_content = [[NSDictionary alloc]
                           initWithObjectsAndKeys:[NSNumber numberWithInt:CONTENTS_MOVIE], @"type",
                           [NSNumber numberWithLongLong:[[content objectForKey:KEY_FINALUPDATE_DATE] longLongValue]], KEY_FINALUPDATE_DATE, nil];
            break;
            
        default:
            NSLog(@"unknown type : %d", type);
            new_content = nil;
            break;
    }
    
    // 新規コンテンツが存在すれば追加する
    if ( new_content ) {
        [contents_list setObject:new_content forKey:content_id];
    }
}

// +++++++++++++++++++++++++++++++++++++++++++++++
//
//  ダウンロード関連
//
// +++++++++++++++++++++++++++++++++++++++++++++++

// --- コンテンツのアップデート ---
bool ContentsUpdateManager::downloadContentsShouldBeUpdated(UIViewController *vc, NSMutableArray* contents_list, AlertUtil::ALERT_TYPE &atype)
{
    // *** プログレスバーの表示 ***
    auto progress = [[MBProgressHUD alloc] initWithView:vc.view];
    progress.labelText = @"ダウンロード中";
    [vc.view addSubview:progress];
    [progress show:YES];
    
    // ローカルのコンテンツリストを取得
    auto local_contents_list = getLocalContentsList();
    
    // *** ローカルコンテンツが存在しない場合 ***
    if ( !local_contents_list ) {
        
        // 全コンテンツのダウンロード
        if ( !downloadAllContents( contents_list, atype ) ) {
    
            // プログレスバーの非表示
            [progress hide:YES];
            [progress removeFromSuperview];
            
            return false;
        }
        
        // ローカル保存用コンテンツリストの生成
        local_contents_list = createLocalContentsList( contents_list );
        
        // コンテンツリストの保存
        saveContentsList( local_contents_list );
    }
    // *** ローカルコンテンツリストが存在する場合 ***
    else {
        
        // 更新日時を比較してダウンロードする
        
        bool exist_content = false; // 対象のコンテンツが存在する？
        
        for ( NSDictionary *content in contents_list ) {
            exist_content = false;
            
            // 新規リストのIDがローカルリストの中にある?
            NSString *content_id = [content objectForKey:@"id"];
            
            auto enums = [local_contents_list keyEnumerator];
            for (NSString* local_id in enums) {
                
                // 同一IDのコンテンツが存在すれば終了
                if ([content_id isEqualToString:local_id]) {
                    exist_content = YES;
                    break;
                }
            }
            
            // 既存リストに存在する
            if ( exist_content ) {
                
                // ローカルオブジェクト情報の取得
                NSDictionary* local_content = [local_contents_list objectForKey:content_id];
                
                // それぞれの更新日時を取得
                long long new_upd_time = [[content objectForKey:KEY_FINALUPDATE_DATE]longLongValue];
                long long prev_upd_time = [[local_content objectForKey:KEY_FINALUPDATE_DATE] longLongValue];
                
                // 更新が発生しているならばダウンロードする
                if ( prev_upd_time < new_upd_time ) {
                    exist_content = NO;
                }
            }
            
            // 最新のコンテンツが存在しないならばダウンロードする
            if ( !downloadContent( content, content_id, !exist_content, atype ) ) {
                
                // プログレスバーの非表示
                [progress hide:YES];
                [progress removeFromSuperview];
                
                return false;
            }
            
            // ダウンロードしたときは追加しておく
            if ( !exist_content ) {
                // リスト二追加
                addContent2List( content, content_id, local_contents_list );
            }
        }
        
        // リストの保存
        saveContentsList( local_contents_list );
    }
    
    // プログレスバーの非表示
    [progress hide:YES];
    [progress removeFromSuperview];
    
    return true;
}

// ***********************************************
// * 全コンテンツの取得
// ***********************************************
bool ContentsUpdateManager::downloadAllContents(NSMutableArray* contents_list, AlertUtil::ALERT_TYPE &atype) {

    // リスト内の全要素に対してダウンロードを実行する
    for (NSDictionary *content in contents_list) {
        
        // ダウンロード二失敗したときは終了
        if ( !downloadContent( content, [content objectForKey:@"id"], true, atype ) ) {
            return false;
        }
    }
    
    return true;
}

// ***********************************************
// * 指定コンテンツのデータダウンロード
// ***********************************************
bool ContentsUpdateManager::downloadContent(NSDictionary* contents, NSString* content_id, bool download, AlertUtil::ALERT_TYPE &atype)
{
    // type IDの取得
    
    int type = [[contents objectForKey:@"type"] intValue];
    
    switch ( type ) {
        case CONTENTS_TOPURL: //TOP画面
            APP_DEL.topURL = [contents objectForKey:@"url"];
            break;
        case CONTENTS_QR_RAYER: //QR読み取り画面
            APP_DEL.qrURL = [contents objectForKey:@"url"];
            break;
        case CONTENTS_MOVIE: //動画
            if ( !download ) break;
            if ( !downloadMultimediaData( content_id, atype ) ) return false;
            break;
        case CONTENTS_SOUND: //サウンド
            if ( !download ) break;
            if ( !downloadMultimediaData( content_id, atype ) ) return false;
        case ERROR_DRAWEROPENED:
            APP_DEL.drawerOpenURL = [contents objectForKey:@"url"];
            break;
        case ERROR_FAILEDTOCUT:
            APP_DEL.failedCutURL = [contents objectForKey:@"url"];
            break;
        case ERROR_HEADERTEMP:
            APP_DEL.headerTempURL = [contents objectForKey:@"url"];
            break;
        case ERROR_PAPEREMPTY:
            APP_DEL.paperEmptyURL = [contents objectForKey:@"url"];
            break;
        case ERROR_PAPERJAMMED:
            APP_DEL.paperJammedURL = [contents objectForKey:@"url"];
            break;
        case ERROR_POWERERROR:
            APP_DEL.powerErrorURL = [contents objectForKey:@"url"];
            break;
        case ERROR_UNUSUALDATA:
            APP_DEL.unusualDataURL = [contents objectForKey:@"url"];
            break;
        case ERROR_PAIRING:
            APP_DEL.pairingUrl = [contents objectForKey:@"url"];
            break;
        default:
            NSLog(@"unknown type : %d", type );
            break;
    }
    
    return true;
}

// ***********************************************
// * マルチメディアデータのダウンロード
// ***********************************************
bool ContentsUpdateManager::downloadMultimediaData(NSString* content_id, AlertUtil::ALERT_TYPE &atype)
{
    
    // 結果
    __block bool result = false;
    
    // 同期通信で動画をダウンロード
    auto request = ConnectionUtil::createRequest([NSString stringWithFormat:@"%@?id=%@", DOWNLOAD_API, content_id], true, nil );
    
    auto conn = [[AsyncURLConnection alloc] initWithRequest:request
                                            timeoutSec:TIMEOUT_INTERVAL

    // 通信成功時
    completeBlock:^(AsyncURLConnection *conn, NSData *data) {
    
        // レスポンスコードの確認
        ConnectionUtil::HTTP_CODE code;
        auto http_response = static_cast< NSHTTPURLResponse* >( conn.response );
        if ( !ConnectionUtil::checkStatusCode( http_response, code ) ) {
            atype = AlertUtil::convert( code, false );
            return;
        }
        
        // 動画保存用パスの生成
        auto movie_path = [NSString stringWithFormat:@"%@.mp4", content_id];
        auto store_path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:movie_path];
        
        // データの保存
        NSError *error = nil;
        [data writeToFile:store_path
                  options:NSDataWritingAtomic
                    error:&error];
        
        result = true;
    }
    progressBlock:nil
    
    // 通信失敗時
    errorBlock:^(AsyncURLConnection *conn, NSError *error) {
    
        atype = ( error.code==NSURLErrorTimedOut ) ? AlertUtil::TIMEDOUT
                                                   : AlertUtil::NETWORK_ERROR;
        
    } ];
    
    // 同期通信の開始
    [conn performRequest];
    [conn join];
    
    return result;
}



