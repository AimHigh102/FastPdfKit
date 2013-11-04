//
//  MenuViewController.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 8/26/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TAG_PASSWORDFIELD 77

@class MFDocumentManager;

@interface MenuViewController : UIViewController {

	IBOutlet UIButton *referenceButton;
	IBOutlet UIButton *manualButton;
	IBOutlet UITextView *referenceTextView;
	IBOutlet UITextView *manualTextView;
	
	MFDocumentManager *document;
	
	UIAlertView * __weak passwordAlertView;
	
	NSString * __weak nomePdfDaAprire;
	
}

-(IBAction)actionOpenPlainDocument:(id)sender;
-(IBAction)actionOpenEncryptedDocument:(id)sender;
-(void)setLinkedDocument:(NSString *)documentName withPage:(NSUInteger)destinationPage orDestinationName:(NSString *)destinationName;
-(void)openDocumentWithParams:(NSArray *)params;

@property (nonatomic, retain) IBOutlet UIButton *referenceButton;
@property (nonatomic, retain) IBOutlet UIButton *manualButton;
@property (nonatomic, retain) IBOutlet UITextView *referenceTextView;
@property (nonatomic, retain) IBOutlet UITextView *manualTextView;

@property (nonatomic, retain) MFDocumentManager *document;
@property (nonatomic, weak) UIAlertView *passwordAlertView;
@property (nonatomic, weak) NSString *nomePdfDaAprire;



@end
