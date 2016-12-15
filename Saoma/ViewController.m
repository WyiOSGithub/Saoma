//
//  ViewController.m
//  Saoma
//
//  Created by wang yu on 16/9/1.
//  Copyright © 2016年 wang yu. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#define SCANVIEW_EdgeTop 40.0
#define SCANVIEW_EdgeLeft 50.0
#define TINTCOLOR_ALPHA 0.2 //浅色透明度
#define DARKCOLOR_ALPHA 0.5 //深色透明度
#define VIEW_WIDTH [UIScreen mainScreen].bounds.size.width
#define VIEW_HEIGHT [UIScreen mainScreen].bounds.size.height
@interface ViewController ()<UIAdaptivePresentationControllerDelegate>
{
    AVCaptureSession * session;//输入输出的中间桥梁
    UIView *AVCapView;//此 view 用来放置扫描框、取消按钮、说明 label
    UIView *_QrCodeline;//上下移动绿色的线条
    NSTimer *_timer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.\
    
    
    //创建一个 view 来放置扫描区域、说明 label、取消按钮
    UIView *tempView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, [UIScreen mainScreen].bounds.size.height )];
    AVCapView = tempView;
    AVCapView.backgroundColor = [UIColor colorWithRed:54.f/255 green:53.f/255 blue:58.f/255 alpha:1];
    
    UIButton *cancelBtn = [[UIButton alloc]initWithFrame:CGRectMake(15, [UIScreen mainScreen].bounds.size.height - 100, 50, 25)];
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 268, 290, 60)];
    label.numberOfLines = 0;
    label.text = @"小提示：将条形码或二维码对准上方区域中心即可";
    label.textColor = [UIColor grayColor];
    [cancelBtn setTitle:@"取消" forState: UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(touchAVCancelBtn) forControlEvents:UIControlEventTouchUpInside];
    [AVCapView addSubview:label];
    [AVCapView addSubview:cancelBtn];
    [self.view addSubview:AVCapView];
    
    
    //画上边框
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(SCANVIEW_EdgeLeft, SCANVIEW_EdgeTop, VIEW_WIDTH- 2 * SCANVIEW_EdgeLeft, 1)];
    topView.backgroundColor = [UIColor whiteColor];
    [AVCapView addSubview:topView];
    
    //画左边框
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(SCANVIEW_EdgeLeft, SCANVIEW_EdgeTop , 1,VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft )];
    leftView.backgroundColor = [UIColor whiteColor];
    [AVCapView addSubview:leftView];
    
    //画右边框
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(SCANVIEW_EdgeLeft + VIEW_WIDTH- 2 * SCANVIEW_EdgeLeft, SCANVIEW_EdgeTop , 1,VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft + 1)];
    rightView.backgroundColor = [UIColor whiteColor];
    [AVCapView addSubview:rightView];
    
    //画下边框
    UIView *downView = [[UIView alloc] initWithFrame:CGRectMake(SCANVIEW_EdgeLeft, SCANVIEW_EdgeTop + VIEW_WIDTH- 2 * SCANVIEW_EdgeLeft,VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft ,1 )];
    downView.backgroundColor = [UIColor whiteColor];
    [AVCapView addSubview:downView];
    
    
    //画中间的基准线
    _QrCodeline = [[UIView alloc] initWithFrame:CGRectMake(SCANVIEW_EdgeLeft + 1, SCANVIEW_EdgeTop, VIEW_WIDTH- 2 * SCANVIEW_EdgeLeft - 1, 2)];
    _QrCodeline.backgroundColor = [UIColor greenColor];
    [AVCapView addSubview:_QrCodeline];
    
    
    // 先让基准线运动一次，避免定时器的时差
    [UIView animateWithDuration:1.2 animations:^{
        
        _QrCodeline.frame = CGRectMake(SCANVIEW_EdgeLeft + 1, VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft + SCANVIEW_EdgeTop , VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft - 1, 2);
        
    }];
    
    [self performSelector:@selector(createTimer) withObject:nil afterDelay:0.4];
    
    
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    //创建输出流
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc]init];
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //初始化链接对象
    session = [[AVCaptureSession alloc]init];
    //高质量采集率
    [session setSessionPreset:AVCaptureSessionPresetHigh];
    
    [session addInput:input];
    [session addOutput:output];
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    layer.frame = CGRectMake(SCANVIEW_EdgeLeft, SCANVIEW_EdgeTop, VIEW_WIDTH- 2 * SCANVIEW_EdgeLeft, 220);
    [AVCapView.layer insertSublayer:layer atIndex:0];
    //开始捕获
    [session startRunning];
}
- (void)createTimer
{
    _timer=[NSTimer scheduledTimerWithTimeInterval:1.1 target:self selector:@selector(moveUpAndDownLine) userInfo:nil repeats:YES];
}

- (void)stopTimer
{
    if ([_timer isValid] == YES) {
        [_timer invalidate];
        _timer = nil;
    }
    
}

// 滚来滚去 :D :D :D
- (void)moveUpAndDownLine
{
    CGFloat YY = _QrCodeline.frame.origin.y;
    
    if (YY != VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft + SCANVIEW_EdgeTop ) {
        [UIView animateWithDuration:1.2 animations:^{
            _QrCodeline.frame = CGRectMake(SCANVIEW_EdgeLeft + 1, VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft + SCANVIEW_EdgeTop , VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft - 1,2);
        }];
    }else {
        [UIView animateWithDuration:1.2 animations:^{
            _QrCodeline.frame = CGRectMake(SCANVIEW_EdgeLeft + 1, SCANVIEW_EdgeTop, VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft - 1,2);
        }];
        
    }
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count>0) {
        //[session stopRunning];
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex : 0 ];
        //输出扫描字符串
        NSLog(@"%@",metadataObject.stringValue);
        [session stopRunning];
        [self stopTimer];
//        [AVCapView removeFromSuperview];
       
    }
}
- (void)touchAVCancelBtn{
    [session stopRunning];//摄像也要停止
    [self stopTimer];//定时器要停止
    [AVCapView removeFromSuperview];//刚刚创建的 view 要移除
    
  
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
