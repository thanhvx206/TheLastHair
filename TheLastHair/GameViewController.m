//
//  GameViewController.m
//  NamiheiHair
//
//  Created by HIDEHIKO KONDO on 2013/04/14.
//  Copyright (c) 2013年 UDONKONET. All rights reserved.
//

#import "GameViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <Social/Social.h>
#import "Bead.h"
#import <MrdIconSDK/MrdIconSDK.h>
#import "GAI.h"

#define MAXHAIR     999999999  //最大値制限
#define ANGRY       250         //怒られる確率
#define COMBO       100         //海平コンボの確率
#define REVIEW      50          //レビューしろアラートを表示するプレイ回数


@interface GameViewController (){
   int nuitaFlg;           //髪の毛を抜いたかどうかの判定
   bool umiheiFlg;          //海平コンボ発動かどうかの判定
   bool umiheiDidEndFlg;    //海平コンボを表示＆計算したかどうかのフラグ
   bool namiheiDidEndFlg;    //波平時の表示＆計算したかどうかのフラグ
   int unplugedNumber;     //抜いた本数
   int gameoverFlg;
   int umiheirnd;
   int angryrnd;
   NSUserDefaults *score;  //スコア保存用
   NSUserDefaults *playCount;  //ゲームをプレイした回数　レビュー以来のアラートの表示に利用
   int playCountBefore;        //プレイ回数の前回値
   
}
@property (nonatomic, retain) MrdIconLoader* iconLoader;//アスタ

@end

@interface GameViewController(MrdIconLoaderDelegate)<MrdIconLoaderDelegate>
@end

@implementation GameViewController
@synthesize unplugLabel;
@synthesize hairImageView;
@synthesize umiheiComboImageView;
@synthesize namiheiFaceImageView;
@synthesize namiheiHeadImageView;
@synthesize bakamonImageView;
@synthesize gameOverView;
@synthesize highScoreLabel;
@synthesize nowScoreLabel;
@synthesize fingerImageView;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
   if (self) {
      // Custom initialization
   }
   return self;
}

- (void)viewDidLoad
{
   [super viewDidLoad];
    
    //google analytics
    self.screenName = @"GameStart";
    
	// Do any additional setup after loading the view.
   //ゲームオーバー画面の角丸設定
   gameOverView.layer.cornerRadius = 10;
   
   //ゲームオーバーフラグを下げる
   gameoverFlg =0;
   
   //抜いたフラグを下げる
   nuitaFlg = 0;
   
   //海平コンボを表示＆計算したかどうかのフラグを下げる
   umiheiDidEndFlg = NO;
   
   //波平時の表示＆計算したかどうかのフラグ下げる
   namiheiDidEndFlg = NO;
   
   //毛を表示
   hairImageView.hidden = NO;
   
   //ハイスコアを読み出し
   score = [NSUserDefaults standardUserDefaults];
   
   //プレイ回数を読み出し
   playCount = [NSUserDefaults standardUserDefaults];
   //userdefaultに保存した値を前回値として読み出し
   playCountBefore = [playCount integerForKey:@"play"];
   
   //抜いた数を0クリア
   unplugedNumber = 0;
   unplugLabel.text = [NSString stringWithFormat:@"%d本抜き",unplugedNumber];
   
   //毛を１８０度回転
   CGAffineTransform rotation = CGAffineTransformMakeRotation(-180.0f * (M_PI / 180.0f));
   [hairImageView setTransform:rotation];
   
   //ランダム値生成
   srand(time(nil));
   
   //アスタ表示
   [self displayIconAdd];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
   //Adstir表示
	// MEDIA-ID,SPOT-NOには、管理画面で発行されたメディアID, 枠ナンバーを埋め込んでください。
	// 詳しくはhttp://wiki.ad-stir.com/%E3%83%A1%E3%83%87%E3%82%A3%E3%82%A2ID%E5%8F%96%E5%BE%97をご覧ください。
	//画面取得
   UIScreen *sc = [UIScreen mainScreen];
   
   //ステータスバー込みのサイズ
   CGRect rect = sc.bounds;
   NSLog(@"%.1f, %.1f", rect.size.width, rect.size.height);
   
   //    self.adview = [[AdstirView alloc]initWithOrigin:CGPointMake(0, rect.size.height-50)];
   self.adview = [[AdstirView alloc]initWithOrigin:CGPointZero];
   self.adview.media = @"MEDIA-f5977393";
	self.adview.spot = 1;
	self.adview.rootViewController = self;
	[self.adview start];
	[self.view addSubview:self.adview];
   
}
- (void)viewWillDisappear:(BOOL)animated
{
	[self.adview stop];
	[self.adview removeFromSuperview];
	self.adview.rootViewController = nil;
	self.adview = nil;
	[super viewWillDisappear:animated];
   
   
}
//音を再生するメソッド
-(void) playSound:(NSString *)filename{
   //OK音再生
   SystemSoundID soundID;
   NSURL* soundURL = [[NSBundle mainBundle] URLForResource:filename
                                             withExtension:@"mp3"];
   AudioServicesCreateSystemSoundID ((__bridge CFURLRef)soundURL, &soundID);
   AudioServicesPlaySystemSound (soundID);
}

#pragma mark - gameover
-(void)gameover{
    //google analytics
    self.screenName = @"GameOver";
    
    //指を非表示
   fingerImageView.hidden = YES;
   [fingerImageView setCenter:CGPointMake(214,38)];
   
   
   //今回の記録がハイスコアを超えたらuserdefaultで保存
   if([score integerForKey:@"SCORE"] < unplugedNumber){
      [score setInteger:unplugedNumber forKey:@"SCORE"];
   }
   
   
   
   //前回値に１を足して保存。
   [playCount setInteger:(playCountBefore+1) forKey:@"play"];
   NSLog(@"プレイ回数：%d",[playCount integerForKey:@"play"]);
   
   //レビュー済みか確認
   BOOL reviewflg = [playCount boolForKey:@"REVIEW"];
   
   NSLog(@"レビュー済み:%d",reviewflg);
   
   //プレイ回数50回毎にレビュー依頼
   if([playCount integerForKey:@"play"]%REVIEW == 0 && reviewflg == NO){
      UIAlertView *alert = [
                            [UIAlertView alloc]
                            initWithTitle:@"ばかも〜ん！！"
                            message:@"遊んでばかりいないで\nレビューを書かんか！！\n（レビュー書くと、このメッセージはもう出ないよ）"
                            delegate:self
                            cancelButtonTitle:@"やだよぉ〜"
                            otherButtonTitles:@"レビューを書く",nil
                            ];
      [alert show];
   }else{
      //アニメーションが終わった後に広告表示
      NSTimer *tm = [NSTimer scheduledTimerWithTimeInterval:1.1f target:self selector:@selector(displayBead:) userInfo:nil repeats:NO];
      
   }
   
   
   //記録を表示
   highScoreLabel.text = [NSString stringWithFormat:@"最高記録：%d本抜き",[score integerForKey:@"SCORE"]];
   nowScoreLabel.text = [NSString stringWithFormat:@"今回記録：%d本抜き",unplugedNumber];
   
   
   //ゲームオーバーフラグをたてる
   gameoverFlg = 1;
   
   //毛を非表示
   hairImageView.hidden = YES;
   
   //バイブレーション発生
   AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
   
   //海平コンボ音再生
   [self playSound:@"gameover"];
   
   
   //顔を表示。頭を非表示。ばかもーんを表示
   namiheiFaceImageView.hidden = NO;
   namiheiHeadImageView.hidden = YES;
   bakamonImageView.hidden = NO;
   
   
   //ばかもんのアニメーション
   bakamonImageView.frame  = CGRectMake(160, 400, 0, 0);
   [UIView beginAnimations:nil context:nil];                   // 条件指定開始
   [UIView setAnimationDuration:1.0];                          // 2秒かけてアニメーションを終了させる
   [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];   // アニメーションは一定速度
   bakamonImageView.frame = CGRectMake(10, 100, 300, 60);            // 終了位置を200,400の位置に指定する
   [UIView commitAnimations];                                  // アニメーション開始！
   
   //スコア表示のアニメーション
   [UIView beginAnimations:nil context:nil];                   // 条件指定開始
   [UIView setAnimationDuration:1.0];                          // 2秒かけてアニメーションを終了させる
   [UIView setAnimationDelay:0.2];                             // 3秒後にアニメーションを開始する
   [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];   // アニメーションは一定速度
   gameOverView.center = CGPointMake(160, 300);                // 終了位置を200,400の位置に指定する
   [UIView commitAnimations];                                  // アニメーション開始！
   
   //    [self.adview setCenter:CGPointMake(160,25)];
   
   
   
}

-(void)displayBead:(NSTimer*)timer{
   
   //bead表示
   NSLog(@"bead表示");
   [[Bead sharedInstance] showWithSID:@"240de5cb325a1c9dfe304691856fe1f5ac7db3f7c4e52001"];
   
}

#pragma mark - タッチイベント
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
   //タッチイベントの設定
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self.view];
	NSInteger taps = [touch tapCount];
	[super touchesBegan:touches withEvent:event];
	NSLog(@"タップ開始 %f, %f  タップ数：%d",location.x, location.y, taps);
   
   //指を表示
   if(gameoverFlg == 0){
      fingerImageView.hidden = NO;
   }
}

//ボタン押下時の処理
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
   
   switch (buttonIndex) {
      case 0://押したボタンがCancelなら何もしない
         break;
         
      case 1://押したボタンがOKなら画面遷移
         //https://itunes.apple.com/us/app/hage-qin-fu-duan-fa-shi/id570377317?mt=8
         
         //playCountにレビューをしたことを記録　ダイアログを出ないようにする。
         [playCount setBool:YES forKey:@"REVIEW"];
         BOOL reviewflg = [playCount boolForKey:@"REVIEW"];
         NSLog(@"レビュー保存:%d  %d",reviewflg,[playCount boolForKey:@"REVIEW"]);

         
         //ストアに遷移
         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=570377317"]];
//         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/jp/app/hage-qin-fu-duan-fa-shi/id570377317?mt=8&uo=4"]];
         //"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id={YOUR APP ID}&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"
         
         break;
   }
}

//ドラッグ中に繰り返し発生
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
   //ゲームオーバーじゃないときだけタッチイベントが有効
   if( gameoverFlg ==0){
      
      //怒り発動の確率設定
      angryrnd = rand()% ANGRY;
      NSLog(@"ばかもん：%d",angryrnd);
      //怒りが0になったらゲームオーバー
      if(angryrnd == 0){
         [self gameover];
      }
      
      
      //タッチイベント設定
      UITouch *touch = [touches anyObject];
      //ドラッグ前の位置
      CGPoint oldLocation = [touch previousLocationInView:self.view];
      //ドラッグ後の位置
      CGPoint newLocation = [touch locationInView:self.view];
      [super touchesMoved:touches withEvent:event];
      
      
      //毛を引っ張ります
      NSLog(@"指の動き：%f , %f から %f, %f", oldLocation.x, oldLocation.y, newLocation.x, newLocation.y);
      
      //ドラッグした位置をもとに、指のY座標を変更
      [fingerImageView setCenter:CGPointMake(214, hairImageView.frame.origin.y + (-1)*(90+oldLocation.y-newLocation.y))];
      
      //ドラッグした位置をもとに、画像の高さとY座標を変更（伸び縮み）
      [hairImageView setFrame:CGRectMake(hairImageView.frame.origin.x,
                                         hairImageView.frame.origin.y + (-1)*(oldLocation.y-newLocation.y),
                                         hairImageView.frame.size.width,
                                         hairImageView.frame.size.height + (oldLocation.y-newLocation.y))];
      
      //毛が縮みます　高さが２０以下、Y座標が200以上、抜けてない時は高さとY座標を固定する（縮みすぎないようにする）
      if(hairImageView.frame.size.height <=20 && hairImageView.frame.origin.y >=200 && nuitaFlg == 0){
         [hairImageView setFrame:CGRectMake(hairImageView.frame.origin.x,220,hairImageView.frame.size.width,20)];
      }
      
      
      //毛が抜けます　Y座標が40以下になった、または抜いた後は毛の高さを70に固定（のばしていた画像を一定の大きさに固定する事によって抜けたように見せる）
      if(hairImageView.frame.origin.y <=50 || nuitaFlg == 1){
         [hairImageView setFrame:CGRectMake(hairImageView.frame.origin.x,hairImageView.frame.origin.y,hairImageView.frame.size.width,70)];
         NSLog(@"100以下だよ");
         nuitaFlg = 1;
         
         //抜けているかどうかの判定
         if(nuitaFlg == 1){
            if (umiheiFlg == YES) {                      //脱毛コンボ発動！脱毛を計算＆アニメが終わっていなければ実行
               if(umiheiDidEndFlg == NO){                  //海平を計算＆アニメが終わっていなければ実行
                  
                  NSLog(@"海平コンボ発動！！ポイント２倍");
                  unplugedNumber *= 2;                     //ポイントを２倍！
                  umiheiDidEndFlg = YES;                    //計算＆アニメーション終了
                  
                  //アニメーション
                  [umiheiComboImageView setHidden:NO];
                  [umiheiComboImageView setAlpha:1];
                  [UIView beginAnimations:nil context:nil];
                  [UIView setAnimationDuration:3.0];
                  [umiheiComboImageView setAlpha:0];
                  [UIView commitAnimations];
                  
                  //ラベルに表示
                  //max9999999999
                  if(unplugedNumber > MAXHAIR){
                     unplugedNumber = MAXHAIR;
                  }
                  unplugLabel.text = [NSString stringWithFormat:@"%d本抜き",unplugedNumber];
                  unplugLabel.textColor = [UIColor redColor];
                  
                  //バイブレーション発生
                  AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                  //海平コンボ音再生
                  [self playSound:@"combo"];
               }
            }else{
               if(namiheiDidEndFlg == NO){
                  namiheiDidEndFlg = YES;
                  //通常時の計算＋ラベル表示＋音再生
                  unplugedNumber++;                        //抜いた本数を加算
                  //max9999999999
                  if(unplugedNumber > MAXHAIR){
                     unplugedNumber = MAXHAIR;
                  }
                  
                  //抜いた音再生
                  [self playSound:@"miss"];
                  
                  //ラベルに表示
                  unplugLabel.text = [NSString stringWithFormat:@"%d本抜き",unplugedNumber];
                  unplugLabel.textColor = [UIColor blackColor];
               }
            }
         }
      }
   }
}

//タッチイベント終了時の処理
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
   
   
   //指を非表示
   fingerImageView.hidden = YES;
   [fingerImageView setCenter:CGPointMake(214,88)];
   
   //ゲームオーバーじゃないときだけ実行
   if(gameoverFlg == 0){
      UITouch *touch = [touches anyObject];
      CGPoint location = [touch locationInView:self.view];
      [super touchesEnded:touches withEvent:event];
      
      //umiheiDidEndFlgを戻す
      umiheiDidEndFlg = NO;
      namiheiDidEndFlg = NO;
      
      
      //抜けたかどうかの判定
      if(nuitaFlg == 1){
         //脱毛コンボ発動？ 100分の１の確率で発動
         umiheirnd = rand()%COMBO;
         if(umiheirnd == 0){
            umiheiFlg = YES;
            [hairImageView setImage:[UIImage imageNamed:@"hairtwin.png"]];  //２本ヘアーを表示
         }else{
            [hairImageView setImage:[UIImage imageNamed:@"hair.png"]];      //１本ヘアーを表示
            umiheiFlg = NO;
         }
         
         //アニメーション ニョキッと生えてきます
         [hairImageView setFrame:CGRectMake(145, 230, 25, 10)];
         [UIView beginAnimations:nil context:nil];
         [UIView setAnimationDuration:0.4];
         [hairImageView setFrame:CGRectMake(145, 180, 25, 60)];
         [UIView commitAnimations];
      }else{
         //失敗再生
         [self playSound:@"unplug"];
         
         //アニメーション 上下にふわふわ動きます。
         [hairImageView setFrame:CGRectMake(145, 200, 25, 40)];
         [UIView beginAnimations:nil context:nil];
         [UIView setAnimationDuration:0.07];
         [UIView setAnimationRepeatCount:4];
         [UIView setAnimationRepeatAutoreverses:YES];
         [hairImageView setFrame:CGRectMake(145, 180, 25, 60)];
         [UIView commitAnimations];
      }
      //抜いたフラグをたてる
      nuitaFlg = 0;
      NSLog(@"タップ終了 %f, %f", location.x, location.y);
   }
   
}

- (IBAction)backButton:(id)sender {
   //終わり音再生
   [self playSound:@"back"];
   [self dismissViewControllerAnimated:NO completion:nil];
}


//アスタ広告
-(void)displayIconAdd{
   //表示するY座標をUDONKOAPPSボタンと同じにする
   NSInteger iconY = 75;
   
   // The array of points used as origin of icon frame
	CGPoint origins[] = {
		{0, iconY},
        {245, iconY},
        {0,iconY+100},
        {245,iconY+100},
        {0,iconY+200},
        {245,iconY+200}
   };
   
   MrdIconLoader* iconLoader = [[MrdIconLoader alloc]init]; // (1)
   self.iconLoader = iconLoader;
	iconLoader.delegate = self;
   //	IF_NO_ARC([iconLoader release];)
   
   
    int iconCount = 6;
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    //4inchの時は４個
    if(screenSize.height < 568){
        iconCount = 4;
    }
   
   for (int i=0; i < iconCount; i++)
	{
      CGRect frame;                                                       //frame
      frame.origin = origins[i];                                          //位置
      frame.size = kMrdIconCell_DefaultViewSize;                          //サイズ75x75
      MrdIconCell* iconCell = [[MrdIconCell alloc]initWithFrame:frame];   //セル生成
      [iconLoader addIconCell:iconCell];                                  //セル追加
      [self.gameOverView addSubview:iconCell];                                    //セル配置
      [iconLoader startLoadWithMediaCode: @"id570377317"];                //ID設定
      _iconLoader = iconLoader;
   }
   
}



- (void)didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}
@end


////////////////////////////////////////////////////////////////////////////////////
#pragma mark - aster広告delegate
@implementation GameViewController(MrdIconLoaderDelegate)

- (void)loader:(MrdIconLoader*)loader didReceiveContentForCells:(NSArray *)cells
{
	for (id cell in cells) {
		NSLog(@"---- The content loaded for iconCell:%p, loader:%p", cell,  loader);
	}
}

- (void)loader:(MrdIconLoader*)loader didFailToLoadContentForCells:(NSArray*)cells
{
	for (id cell in cells) {
		NSLog(@"---- The content is missing for iconCell:%p, loader:%p", cell,  loader);
	}
}

- (BOOL)loader:(MrdIconLoader*)loader willHandleTapOnCell:(MrdIconCell*)aCell
{
	NSLog(@"---- loader:%p willHandleTapOnCell:%@", loader, aCell);
	return YES;
}

- (void)loader:(MrdIconLoader*)loader willOpenURL:(NSURL*)url cell:(MrdIconCell*)aCell
{
	NSLog(@"---- loader:%p willOpenURL:%@ cell:%@", loader, [url absoluteString], aCell);
}


@end
