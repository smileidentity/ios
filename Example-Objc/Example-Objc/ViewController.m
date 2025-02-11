#import "ViewController.h"
#import "Example_Objc-Swift.h"

@import SmileID;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"Smile ID Products"];
    [[[self navigationController] navigationBar] setPrefersLargeTitles:YES];
}

- (IBAction)smartSelfieTapped:(id)sender {
    [self showSmartSelfieCapture];
}

- (IBAction)enhancedSelfieTapped:(id)sender {
    [self showEnhancedSelfieCapture];
}

- (void)showSmartSelfieCapture {
    SelfieCaptureViewController *selfieVC = [[SelfieCaptureViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:selfieVC];
    [navController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)showEnhancedSelfieCapture {
    EnhancedSelfieCaptureViewController *selfieVC = [[EnhancedSelfieCaptureViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:selfieVC];
    [navController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:navController animated:YES completion:nil];
}


@end
