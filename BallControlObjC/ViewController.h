
#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIBarButtonItem *connectButton;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)pressedConnect:(id)sender;

@end

