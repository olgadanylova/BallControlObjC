
#import "ViewController.h"
#import "Backendless.h"

#define SHARED_OBJECT_NAME @"BallObject"

#define HOST_URL @"http://apitest.backendless.com"
#define APP_ID @"A81AB58A-FC85-EF00-FFE4-1A1C0FEADB00"
#define API_KEY @"FE202648-517E-B0A5-FF89-CBA9D7DFDD00"

@interface ViewController() {
    CGPoint location;
    CGFloat statusBarHeight;
    CGFloat navBarHeight;
    NSDictionary *locationDictionary;
    SharedObject *sharedObject;
}
@property (nonatomic) CGFloat workspaceMinX;
@property (nonatomic) CGFloat workspaceMaxX;
@property (nonatomic) CGFloat workspaceMinY;
@property (nonatomic) CGFloat workspaceMaxY;
@property (nonatomic) CGFloat coefficientX;
@property (nonatomic) CGFloat coefficientY;
@property (nonatomic) BOOL isDragging;
@property (nonatomic) BOOL imageMoveEnabled;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    navBarHeight = self.navigationController.navigationBar.frame.size.height;
    statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    
    self.isDragging = NO;
    self.workspaceMinX = 0;
    self.workspaceMaxX = self.view.frame.size.width - self.imageView.frame.size.width;
    self.workspaceMinY = statusBarHeight + navBarHeight;
    self.workspaceMaxY = self.view.frame.size.height - self.imageView.frame.size.height;
    [self calculateCoefficient];
    
    self.textView.hidden = NO;
    self.imageView.hidden = YES;
    self.imageMoveEnabled = NO;
    self.connectButton.enabled = NO;
    
    backendless.hostURL = HOST_URL;
    [backendless initApp:APP_ID APIKey:API_KEY];
    
    sharedObject = [backendless.sharedObject connect:SHARED_OBJECT_NAME];
    [sharedObject get:@"locationCoefitients" response:^(id result) {
        NSDictionary *locationDictionary = [NSDictionary dictionaryWithDictionary:result];
        float coefX = [[locationDictionary valueForKey:@"coefX"] doubleValue];
        float coefY = [[locationDictionary valueForKey:@"coefY"] doubleValue];
        [UIView animateWithDuration:0.3 animations:^{
            CGFloat originX = coefX * self.workspaceMaxX;
            CGFloat originY = coefY * (self.workspaceMaxY - self.workspaceMinY);
            self.imageView.frame = CGRectMake(originX, originY, self.imageView.frame.size.width, self.imageView.frame.size.height);
        }];
    } error:^(Fault *fault) {
        [self showErrorAlert:fault.detail];
    }];
    [self addOnChangesListener];
    [self addRTListeners];
}

-(void)calculateCoefficient {
    self.coefficientX = self.imageView.frame.origin.x / self.workspaceMaxX;
    self.coefficientY = self.imageView.frame.origin.y / (self.workspaceMaxY);
    if (self.coefficientX < 0) {
        self.coefficientX = 0;
    }
    else if (self.coefficientX > 1) {
        self.coefficientX = 1;
    }
    if (self.coefficientY < 0) {
        self.coefficientY = 0;
    }
    else if (self.coefficientY > 1) {
        self.coefficientY = 1;
    }
}

-(void)addRTListeners {
    __weak __block SharedObject *weakSharedObject = sharedObject;
    [backendless.rt addConnectEventListener:^{
        if ([self.connectButton.title isEqualToString:@"Connect"]) {
            self.navigationItem.title = @"Status: disconnected";
        }
        else if ([self.connectButton.title isEqualToString:@"Disconnect"]) {
            self.navigationItem.title = @"Status: connected";
        }
        if (!weakSharedObject.isConnected) {
            [weakSharedObject connect];
        }
        self.connectButton.enabled = YES;
    }];
    
    [backendless.rt addConnectErrorEventListener:^(NSString *connectError) {
        weakSharedObject = [backendless.sharedObject connect:SHARED_OBJECT_NAME];
        [self addOnChangesListener];
        NSLog(@"Status: connection failed. Reason: %@", connectError);
        self.connectButton.enabled = NO;
    }];
    
    [backendless.rt addDisonnectEventListener:^(NSString *disconnectReason) {
        weakSharedObject = [backendless.sharedObject connect:SHARED_OBJECT_NAME];
        [self addOnChangesListener];
        self.navigationItem.title = [NSString stringWithFormat:@"Status: disconnected. Reason: %@)", disconnectReason];
        self.connectButton.enabled = NO;
    }];
    
    [backendless.rt addReconnectAttemptEventListener:^(ReconnectAttemptObject *reconnectAttempt) {
        NSLog(@"Status: trying to connect");
    }];
}

-(void)addOnChangesListener {
    __weak __block ViewController *weakSelf = self;
    [sharedObject addChangesListener:^(SharedObjectChanges *changes) {
        float coefX = [[changes.data valueForKey:@"coefX"] floatValue];
        float coefY = [[changes.data valueForKey:@"coefY"] floatValue];
        CGFloat originX = coefX * self.workspaceMaxX;
        CGFloat originY = coefY * self.workspaceMaxY;
        if (originY < self.workspaceMinY) {
            originY = self.workspaceMinY;
        }
        if (!weakSelf.isDragging) {
            [UIView animateWithDuration:0.3 animations:^{
                weakSelf.imageView.frame = CGRectMake(originX, originY, weakSelf.imageView.frame.size.width, weakSelf.imageView.frame.size.height);
            }];
        }
    } error:^(Fault *fault) {
        [weakSelf showErrorAlert:fault.detail];
    }];
}

- (IBAction)animate:(id)sender {
    locationDictionary = sender;
    
    float coefX = [[locationDictionary valueForKey:@"coefX"] floatValue];
    float coefY = [[locationDictionary valueForKey:@"coefY"] floatValue];
    
    CGFloat originX = coefX * self.workspaceMaxX;
    CGFloat originY = coefY * self.workspaceMaxY;
    
    if (originX <= CGRectGetMinX(self.view.frame)) {
        originX = CGRectGetMinX(self.view.frame);
    }
    if (originX + self.imageView.frame.size.width >= CGRectGetMaxX(self.view.frame)) {
        originX = CGRectGetMaxX(self.view.frame) - self.imageView.frame.size.width;
    }
    if (originY <= self.workspaceMinY) {
        originY = self.workspaceMinY;
    }
    if (originY + self.imageView.frame.size.height >= CGRectGetMaxY(self.view.frame)) {
        originY = CGRectGetMaxY(self.view.frame) - self.imageView.frame.size.height;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.imageView.frame = CGRectMake(originX, originY, self.imageView.frame.size.width, self.imageView.frame.size.height);
    }];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.isDragging = YES;
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.isDragging = NO;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self calculateCoefficient];    
    if (self.imageMoveEnabled) {
        UITouch *touch = [touches anyObject];
        location = [touch locationInView:self.view];
        self.imageView.center = location;
        locationDictionary = @{@"coefX" : [NSNumber numberWithFloat:self.coefficientX], @"coefY" : [NSNumber numberWithFloat:self.coefficientY]};
        __weak ViewController *weakSelf = self;
        [sharedObject set:@"locationCoefitients" data:locationDictionary response:^(id result) {
        } error:^(Fault *fault) {
            [weakSelf showErrorAlert:fault.detail];
        }];
        if (location.x - self.imageView.frame.size.width / 2 <= CGRectGetMinX(self.view.frame)) {
            location.x = self.imageView.frame.size.width / 2;
        }
        if (location.x + self.imageView.frame.size.width / 2 >= CGRectGetMaxX(self.view.frame)) {
            location.x = CGRectGetMaxX(self.view.frame) - self.imageView.frame.size.width / 2;
        }
        if (location.y - self.imageView.frame.size.height / 2 <= self.workspaceMinY) {
            location.y = statusBarHeight + navBarHeight + self.imageView.frame.size.height / 2;
        }
        if (location.y + self.imageView.frame.size.height / 2 >= CGRectGetMaxY(self.view.frame)) {
            location.y = CGRectGetMaxY(self.view.frame) - self.imageView.frame.size.height / 2;
        }
        self.imageView.center = location;
    }
}

- (void)showErrorAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:^{
        self.textView.hidden = NO;
        self.imageView.hidden = YES;
        self.imageMoveEnabled = NO;
    }];
}

- (IBAction)pressedConnect:(id)sender {
    __weak ViewController *weakSelf = self;
    if ([self.connectButton.title isEqualToString:@"Connect"]) {
        self.connectButton.title = @"Disconnect";
        if (!sharedObject.isConnected) {
            [sharedObject connect];
        }
        [sharedObject addConnectListener:^{
            weakSelf.navigationItem.title = @"Status: connected";
            weakSelf.textView.hidden = YES;
            weakSelf.imageView.hidden = NO;
            weakSelf.imageMoveEnabled = YES;
        } error:^(Fault *fault) {
            [weakSelf showErrorAlert:fault.detail];
        }];
    }
    else if ([self.connectButton.title isEqualToString:@"Disconnect"]) {
        weakSelf.connectButton.title = @"Connect";
        weakSelf.navigationItem.title = @"Status: disconnected";
        weakSelf.textView.hidden = NO;
        weakSelf.imageView.hidden = YES;
        weakSelf.imageMoveEnabled = NO;
        [sharedObject disconnect];
    }
}
@end
