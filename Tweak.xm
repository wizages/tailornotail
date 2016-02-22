#import "TNTPreferencesManager.h"
@interface IMItem : NSObject

@property (nonatomic) long long type;
@property (nonatomic) long long messageID;
@property (nonatomic, retain) NSString *unformattedID;
@property (nonatomic, retain) NSString *service;

@property (nonatomic, retain) NSString *account;
@property (nonatomic, retain) NSString *accountID;
@property (nonatomic, retain) NSString *handle;
@property (nonatomic, retain) NSString *countryCode;
@property (nonatomic, retain) NSString *guid;

@property (nonatomic, retain) NSString *roomName;
@property (nonatomic, retain) NSString *sender;
@property (nonatomic, retain) NSDictionary *senderInfo;

@property (nonatomic, readonly) BOOL isFromMe;
@property (nonatomic, retain) id context;
@property (nonatomic, retain) NSDate *time;

@end

@interface NSConcreteAttributedString : NSAttributedString
- (id)attributesAtIndex:(unsigned int)arg1 effectiveRange:(NSRange *)arg2;
- (id)string;
@end

@interface IMChatItem : NSObject
-(IMItem *)_item;
@end

@interface IMTranscriptChatItem : IMChatItem
@end

@interface CKChatItem : NSObject
@property (nonatomic, retain) IMTranscriptChatItem *IMChatItem;
@end

static bool isSMS;
static bool fromMoi;
static NSString *const kTNTTopColor = @"TopColor";
static NSString *const kTNTBotColor = @"BotColor";
static NSString *const kTNTSender = @"sender";
static NSString *const kTNTReceived = @"received";

%hook CKBalloonView
-(BOOL)hasTail
{
	if([TNTPreferencesManager sharedInstance].enabled){
		if ([TNTPreferencesManager sharedInstance].imessageEnable && !isSMS)
			return [TNTPreferencesManager sharedInstance].enableiMessageTails;
		else if ([TNTPreferencesManager sharedInstance].smsEnable && isSMS)
			return [TNTPreferencesManager sharedInstance].enablesmsTails;
		else
			return [TNTPreferencesManager sharedInstance].enableTails;
	}
	else
		return %orig;
}
-(unsigned int) balloonCorners
{
	return %orig;
}

%end


%hook CKTranscriptCell

-(void)configureForChatItem:(id)arg1
{
	CKChatItem *chatItem = arg1;
	//HBLogDebug(@"Item: %@, %d", [[[chatItem IMChatItem] _item] service], (int)[[[chatItem IMChatItem] _item] isFromMe])
	if([[[[chatItem IMChatItem] _item] service] isEqualToString:@"SMS"])
		isSMS = true;
	else
		isSMS = false;
	fromMoi = [[[chatItem IMChatItem] _item] isFromMe];
	%orig;
}

%end


%hook CKTextBalloonView

-(NSConcreteAttributedString *)attributedText
{
	NSConcreteAttributedString *test = %orig;
	//NSMutableArray *array = [test attributesAtIndex:0 effectiveRange:nil];
	//HBLogDebug(@"Test: %@", );
	NSMutableDictionary *m = [[test attributesAtIndex:0 effectiveRange:nil] mutableCopy];
	m[@"NSColor"] = [UIColor whiteColor];

	NSConcreteAttributedString *test2 = [[NSConcreteAttributedString alloc] initWithString:[test string] attributes:m];
	return test2;
}

%end

%hook CKColoredBalloonView

-(BOOL) color {
	//HBLogDebug(@"Called Color, %d", (int) isSMS)
	if([TNTPreferencesManager sharedInstance].enabled)
		return true;
	else
		return %orig;
}

%end

%hook CKGradientView

-(id)colors
{
	TNTPreferencesManager *pref = [TNTPreferencesManager sharedInstance];
	//HBLogDebug(@"Called Colors, %d", (int) isSMS)
	NSDictionary *dictionary;
	if(pref.enabled){
		if(pref.imessageEnable && !isSMS)
			dictionary = [pref getPrefDictionary:@"imessage"];
		else if(pref.smsEnable && isSMS)
			dictionary = [pref getPrefDictionary:@"sms"];
		else
			dictionary = [pref getPrefDictionary:@"default"];
		
		NSMutableArray *arrays = [NSMutableArray array];
		if(fromMoi)
		{
			[arrays addObject:dictionary[[NSString stringWithFormat:@"%@-%@", kTNTSender, kTNTBotColor]]];
			[arrays addObject:dictionary[[NSString stringWithFormat:@"%@-%@", kTNTSender, kTNTTopColor]]];
		}
		else
		{
			[arrays addObject:dictionary[[NSString stringWithFormat:@"%@-%@", kTNTReceived, kTNTBotColor]]];
			[arrays addObject:dictionary[[NSString stringWithFormat:@"%@-%@", kTNTReceived, kTNTTopColor]]];
		}
		return arrays;
	}
	else
		return %orig;
}

%end