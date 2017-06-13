//
//  ViewController.m
//  RAC
//
//  Created by wdwk on 2017/6/7.
//  Copyright © 2017年 wksc. All rights reserved.
//

#import "ViewController.h"
#import "ReactiveObjC.h"
#import "Person.h"
@interface ViewController ()
@property(nonatomic, strong)Person *p;
@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet UIButton *btn;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
// 绑定两个文本框信号进行监听，并返回bool值；
//    对登录按钮进行状态监听；RAC宏；
   RAC(_loginBtn,enabled)= [RACSignal combineLatest:@[_textField.rac_textSignal,_passwordTextField.rac_textSignal] reduce:^id _Nullable(NSString *accout,NSString * password){
        //判断账号和密码是否有内容；
        return @(accout.length&&password.length);
    }];


    RACCommand * command=[[RACCommand alloc]initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
       return  [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            //  获取登录结果
            [subscriber sendNext:@"请求登录的数据"];
           //告诉信号结束，后面才能顺利进行接下来的操作；
           [subscriber sendCompleted ];
            return nil;
        }];
        return nil;
    }];
//    执行命令
//    switchToLatest订阅最新的信号；
    [command.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        NSLog(@"---%@",x);
    }];
    //命令执行中也是一个信号；
     //监听命令的过程；
    [[command.executing skip:1]subscribeNext:^(NSNumber * _Nullable x) {
        if ([x boolValue]) {
            NSLog(@"正在等待");
            
        }
        else{
            NSLog(@"数据完成");
        }
    }];
//    [command.executing subscribeNext:^(NSNumber * _Nullable x) {
//       
//        
//    }]
    //    监听按钮状态
    [[_loginBtn rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(__kindof UIControl * _Nullable x) {
        NSLog(@" 当按钮击的事件就写在这里了");
        //执行命令
        [command execute:nil];
    }];
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.p.name=[NSString stringWithFormat:@"%d",arc4random_uniform(50)];
}
-(void)demo7{
    
    //    RAC 命令----command
    //    1、创建命令；
    RACCommand * command=[[RACCommand alloc]initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        //        input执行命令里面的内容
        NSLog(@"%@",input);
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            //发送
            [subscriber sendNext:@"我是从命令中发出的信号"];
            return nil  ;
        }];
    }];
    //    2、执行命令,订阅信号
    [[command execute:@"执行命令"] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    } ];

}
-(void)demo6{
    //ARC的坑----循环引用；在RAC中有99。99..%可能会造成循环引用；解决的办法是    @weakify(self)@strongify(self)
    //RAC 代替Target,生成了一个信号；
    
    @weakify(self)
    [[self.btn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        //现在x是按钮本省；
        @strongify(self)
        self.textField.text=@"ggg";
        NSLog(@"做按钮点击之后相应的操作");
    }];
}
-(void)demo5{
    //通知：
    //    先拿到通知中心；
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        //x指通知本身的内容；
        NSLog(@"notification:%@",x);
    }];
}
-(void)demo4{
    //监听文本框
    [[self.textField rac_textSignal] subscribeNext:^(NSString * _Nullable x) {
        //x文本框内容变化的监听；并且能够监听中文；
        NSLog(@"x=%@",x);
    }];
}
-(void)demo3{
    //RAC 代替Target,生成了一个信号；
    [[self.btn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        //现在x是按钮本省；
        NSLog(@"做按钮点击之后相应的操作");
    }];
}
-(void)demo2{
    //RAC代替KVO，这里需要移除监听RAC已经帮我们做了；
    self.p=[Person new];
    [RACObserve(self, p.name) subscribeNext:^(id  _Nullable x) {
        NSLog(@"学：%@",x);
        self.nameLab.text=x;
    }];
}
-(void)demo1{
//    一、RAC原理
    //    RACSignal
    //    1、创建信号，RACDynamicSignal，didSubscribe；
    //    创建信号的时候做了两件事情：1、创建了RACDynamicSignal动态信号，2.保存了block叫做didSubscribe
    RACSignal * signal=[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //        在创建信号里面进行信号的发送，subscriber信号订阅者；
        NSLog(@"我创建信号");
        // 3、发送信号，还执行了nextBlock
        [subscriber sendNext:@"this a RAC"] ;
        NSLog(@"我发送信号");
        return nil   ;
    }];
    //    2、订阅信号，创建了订阅者RACSubscriber,保存了nextBlock，执行了didSubscribe
    [signal subscribeNext:^(id  _Nullable x) {
        //      x信号的内容
        NSLog(@"我订阅信号");
    }];
    //    信号之间的关系：
    //    1、要创建信号，必须先订阅信号
    //    2、要订阅信号，必须先发送信号
    //    3、要发送信号，必须先创建信
    
//    一行代码，创建信号，订阅信号，发送信号
    [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
         NSLog(@"我创建信号");
        [subscriber sendNext:@"this a RAC"] ;
        NSLog(@"我发送信号");
        return nil   ;
        
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"我订阅信号");
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
