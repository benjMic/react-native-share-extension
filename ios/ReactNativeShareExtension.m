#import "ReactNativeShareExtension.h"
#import "React/RCTRootView.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define URL_IDENTIFIER @"public.url"
#define IMAGE_IDENTIFIER @"public.image"
#define TEXT_IDENTIFIER (NSString *)kUTTypePlainText
#define DATA_IDENTIFIER (NSString *)kUTTypePropertyList

NSExtensionContext* extensionContext;

@implementation ReactNativeShareExtension {
    NSTimer *autoTimer;
    NSString* type;
    NSString* value;
}

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (UIView*) shareView {
    return nil;
}

RCT_EXPORT_MODULE();

- (void)viewDidLoad {
    [super viewDidLoad];

    //object variable for extension doesn't work for react-native. It must be assign to gloabl
    //variable extensionContext. in this way, both exported method can touch extensionContext
    extensionContext = self.extensionContext;

    UIView *rootView = [self shareView];
    if (rootView.backgroundColor == nil) {
        rootView.backgroundColor = [[UIColor alloc] initWithRed:1 green:1 blue:1 alpha:0.1];
    }

    self.view = rootView;
}


RCT_EXPORT_METHOD(close) {
    [extensionContext completeRequestReturningItems:nil
                                  completionHandler:nil];
}



RCT_EXPORT_METHOD(openURL:(NSString *)url) {
  UIApplication *application = [UIApplication sharedApplication];
  NSURL *urlToOpen = [NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  [application openURL:urlToOpen options:@{} completionHandler: nil];
}



RCT_REMAP_METHOD(data,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    [self extractDataFromContext: extensionContext withCallback:^(NSString* val, NSString* contentType, NSException* err) {
        if(err) {
            reject(@"error", err.description, nil);
        } else {
            resolve(@{
                      @"type": contentType,
                      @"value": val
                      });
        }
    }];
}

- (void)extractDataFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSString *value, NSString* contentType, NSException *exception))callback {
    @try {

        NSItemProvider *urlProvider = nil;
        NSItemProvider *imageProvider = nil;
        NSItemProvider *textProvider = nil;
        NSItemProvider *dataProvider = nil;

        for (NSExtensionItem *item in context.inputItems) {
          for (NSItemProvider *provider in item.attachments) {
            if ([provider hasItemConformingToTypeIdentifier:DATA_IDENTIFIER]){
                dataProvider = provider;
                // break;
            } else if([provider hasItemConformingToTypeIdentifier:URL_IDENTIFIER]) {
                urlProvider = provider;
                // break;
            } else if ([provider hasItemConformingToTypeIdentifier:TEXT_IDENTIFIER]){
                textProvider = provider;
                // break;
            } else if ([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER]){
                imageProvider = provider;
                // break;
            }
          }
        }

        if(dataProvider) {
            [dataProvider loadItemForTypeIdentifier:DATA_IDENTIFIER options:nil completionHandler:^(NSDictionary *item, NSError *error) {
                NSDictionary *results = (NSDictionary *)item;
                NSDictionary *jsPreprocessingResults = results[NSExtensionJavaScriptPreprocessingResultsKey];
                NSString *documentData = [[results objectForKey:NSExtensionJavaScriptPreprocessingResultsKey] objectForKey:@"documentData"];
                // See /ios/PlaypostShareExtension/GetDocumentData.js for which data we get

                if(callback) {
                    callback(documentData, @"text/json", nil);
                }
            }];
        } else if(urlProvider) {
            [urlProvider loadItemForTypeIdentifier:URL_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                NSURL *url = (NSURL *)item;

                if(callback) {
                    callback([url absoluteString], @"text/plain", nil);
                }
            }];
        } else if (textProvider) {
            [textProvider loadItemForTypeIdentifier:TEXT_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                NSString *text = (NSString *)item;

                if(callback) {
                    callback(text, @"text/plain", nil);
                }
            }];
        } else if (imageProvider) {
            [imageProvider loadItemForTypeIdentifier:IMAGE_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                
                // Thanks to iOS 11's new Screenshot Editor, there is a chance id<NSSecureCoding> item will be a UIImage instead of a NSURL, therefore we need to handle both cases
                if ([(NSObject *)item isKindOfClass:[UIImage class]]){
                    // Cast the item to a UIImage and save into a temporary directory so we can pass a URL back to React Native
                    UIImage *sharedImage = (UIImage *)item;
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"RNSE_TEMP_IMG.png"];
                    [UIImagePNGRepresentation(sharedImage) writeToFile: filePath atomically: YES];
                    
                    if(callback){
                        callback(filePath, @"png", nil);
                    }
                    
                }else if ([(NSObject *)item isKindOfClass:[NSURL class]]){
                    NSURL* url = (NSURL *)item;
                    if(callback) {
                        callback([url absoluteString], [[[url absoluteString] pathExtension] lowercaseString], nil);
                    }
                }
            }];
        } else {
            if(callback) {
                callback(nil, nil, [NSException exceptionWithName:@"Error" reason:@"couldn't find provider" userInfo:nil]);
            }
        }
    }
    @catch (NSException *exception) {
        if(callback) {
            callback(nil, nil, exception);
        }
    }
}

@end
