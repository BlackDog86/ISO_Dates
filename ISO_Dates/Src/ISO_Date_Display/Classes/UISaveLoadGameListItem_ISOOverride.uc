class UISaveLoadGameListItem_ISOOverride extends UISaveLoadGameListItem 
	dependson(XComOnlineEventMgr);
	
	// For Reference - This is the structure of the save file headers:

	//Descriptions Array - When we're in mission: (header length = 7)
	//6/13/2023										Descriptions[0]	- Save Date		
	//23:14											Descriptions[1] - Save Time
	//My Special Save Game 1						Descriptions[2] - Player Description (Typed)
	//Rescue VIP from ADVENT Vehicle				Descriptions[3] - Mission type (or geoscape)
	//Operation Massive Willy						Descriptions[4] - Mission Name (optional - may not exist in the array)
	//10/17/2035									Descriptions[5] - In-Game Date
	//11:41 PM ADVENT Patrol Area, Mexico City		Descriptions[6] - In-Game Time & Area

	//Descriptions Array - When we're on the geoscape (header length = 6)
	//6/13/2023										Descriptions[0]	- Save Date		
	//23:14											Descriptions[1] - Save Time
	//My Special Save Game 2						Descriptions[2] - Player Description (Typed)
	//Geoscape										Descriptions[3] - Mission type (or geoscape)
	//10/17/2035									Descriptions[4] - In-Game Date
	//11:41 PM										Descriptions[5] - In-Game Time & Area


	`include(ISO_Date_Display\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

simulated function UpdateData(OnlineSaveGame save)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local XComOnlineEventMgr OnlineEventMgr;
	local string FriendlyName, mapPath, strDate, strName, strMission, strTime;
	local array<string> Descriptions;	
	local SaveGameHeader Header;
	local bool bIsNewSave, bHasValidImage;
	local array<string> saveDateArray;
	local array<string> gameDateArray;
	local array<string> dateTimeArray;
	local string gameTime;
	local int gameHour;
	local string gameHourString;
	local int gameMinute;
	local string gameMinuteString;

	OnlineEventMgr = `ONLINEEVENTMGR;	
	if(save.Filename == "")
	{		
		bIsNewSave = true; 
		OnlineEventMgr.FillInHeaderForSave(Header, FriendlyName);
	}
	else
	{
		Header = save.SaveGames[0].SaveGameHeader;
	}

	MC.FunctionBool("SetAutosave", Header.bIsAutosave);

	bIsDifferentLanguage = (Header.Language != GetLanguage());

	//Split up all the descriptions in the file header (you can see these by opening a save file with a text editor)	
	Descriptions = SplitString(Header.Description, "\n");	
	//The date and time are concatenated together in a single header - split these into two seperate array elements
	dateTimeArray = SplitString(FormatTime(Header.Time), " - ");
	//Now split the save game date into 3 strings & store in seperate array (of months/days/years)
	saveDateArray=SplitString(Descriptions[0],"/");

	// Append zeros to the month & day if needed
	if (len(saveDateArray[0]) == 1)
	{
		saveDateArray[0] = "0" $ saveDateArray[0];
	}
	if (len(saveDateArray[1]) == 1)
	{
		saveDateArray[1] = "0" $ saveDateArray[1];
	}
	if (len(DateTimeArray[1]) == 4)
	//e.g. A 24h clock time is listed as 1:34 onstead of 01:34
	{
		DateTimeArray[1] = "0" $ DateTimeArray[1];
	}	
	//Parse Ironman desc.
	If(InStr(Descriptions[2],class'XComOnlineEventMgr'.default.m_strIronmanLabel) !=INDEX_NONE)
	{
		Descriptions[2] = class'XComOnlineEventMgr'.default.m_strIronmanLabel;
	}

	//For old save files that used "-"
	if( Descriptions.length < 2 )
		Descriptions = SplitString(Header.Description, "-");

	// Handle weirdness
	if(Descriptions.Length < 4)
	{
		strDate = Repl(Header.Time, "\n", " - ") @ Header.Description;
	
		//Handle "custom" description such as what the error reports use
		MC.FunctionBool("SetErrorReport", true);
	}
	else
	{
		//We've made a normal save game
		strTime = saveDateArray[2] $'-'$ saveDateArray[0] $'-'$ saveDateArray[1] $' - '$ dateTimeArray[1] $' - '; // This is actually the date & time concatenated together
		strDate = strTime $ (Descriptions.Length >= 3 ? Descriptions[2] : ""); // This goes on the first line of the save/load box (Date + time + user save description)
		
		if (Descriptions.Length == 7) // We saved in a mission
		{
			if(mid(Descriptions[6],1,1) == ":")
			{
				Descriptions[6] = "0" $ Descriptions[6]; //Ensure the time part is a consistent length irrespective of the 12h time in the header
			}

			//Process the 'in-game' time 
			gameHour=Int(Left(Descriptions[6],2));			//Put the in-game time into integer variables
			gameMinute=Int(Mid(Descriptions[6],3,2));		
				
			If(InStr(Left(Descriptions[6],8),"PM") !=INDEX_NONE )		
			{							
				gameHour=Int(Left(Descriptions[6],2));	//If "PM" is in the string & it's not 12pm, add 12
						
				if(gameHour < 12 && `GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK))
				{
					gameHour += 12;
				}
			}			
			
			gameHourString="";
			gameHourString$=gameHour;
				
			If (Len(gameHourString)==1)
			{
				gameHourString="0"$gameHourString;			//Append leading 0
			}
			gameMinuteString="";
			gameMinuteString$=gameMinute;					//Append leading 0
				
			If (Len(gameMinuteString)==1)
			{
				gameMinuteString="0"$gameMinuteString;
			}

			if (`GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK))
			{	
				gameTime=gameHourString$":"$gameMinuteString;
			}
			else
			{
				gameTime=left(Descriptions[6],8);
			}
				
			strName = Descriptions[3];	//Put the mission type on the second line

			gameDateArray=SplitString(Descriptions[5],"/");		//Split in the in-game date up into 3 strings
				
			if (len(gameDateArray[0]) == 1)					// Append zeroes to months & days if needed
			{
				gameDateArray[0] = "0" $ gameDateArray[0];
			}
				if (len(gameDateArray[1]) == 1)
				{
				gameDateArray[1] = "0" $ gameDateArray[1];
				}			
			
			strMission = gameDateArray[2] $'-'$ gameDateArray[0] $'-'$ gameDateArray[1];	//Re-arrange the date strings

			if(`GETMCMVAR(SHOW_MISSION_LOCATION_ON_SAVE_LOAD))
			{
				strMission $= ' - '$ gameTime $ ' - ' $ Split(Mid(Descriptions[6],8,200)," ",true); // This is the final line in the save box (i.e in-game-date + time + description)
			}
			else
			{
				strMission $= ' - '$ gameTime $ ' - ' $ Descriptions[4];						// This is the final line in the save box (i.e in-game-date + time + location)
			}
		}
			
		if (Descriptions.Length == 6) // We saved on the Geoscape
		{
			if(mid(Descriptions[5],1,1) == ":")
			{
				Descriptions[5] = "0" $ Descriptions[5]; //Ensure the time part is a consistent length irrespective of the 12h time in the header
			}
			
			gameHour=Int(Left(Descriptions[5],2));			//Put the in-game time into integer variables	
			gameMinute=Int(Mid(Descriptions[5],3,2));		
				
			If(InStr(Left(Descriptions[5],8),"PM") !=INDEX_NONE)		
			{			
				gameHour=Int(Left(Descriptions[5],2));	//If "PM" is in the string, add 12							
				if(gameHour < 12 && `GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK))
				{
					gameHour += 12;
				}					
			}	
					
			gameHourString="";
			gameHourString$=gameHour;

			If (Len(gameHourString)==1)
			{
				gameHourString="0"$gameHourString;
			}
			gameMinuteString="";
			gameMinuteString$=gameMinute;					//Append leading 0
			
			If (Len(gameMinuteString)==1)
			{
				gameMinuteString="0"$gameMinuteString;
			}

			gameTime=gameHourString$":"$gameMinuteString;
			
			strName = Descriptions[3];							//Just output "geoscape" since there are no mission details
			gameDateArray=SplitString(Descriptions[4],"/");		//As before - note that the array elements are now offset by one compared with the in-mission saves
			if (len(gameDateArray[0]) == 1)
			{
				gameDateArray[0] = "0" $ gameDateArray[0];
			}
			if (len(gameDateArray[1]) == 1)
			{
				gameDateArray[1] = "0" $ gameDateArray[1];
			}
			strMission = gameDateArray[2] $'-'$ gameDateArray[0] $'-'$ gameDateArray[1];
			
			if (`GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK))
			{	
				strMission $= ' - ' $ gameTime;
			}
				else
			{
				strMission $= ' - ' $ Descriptions[5];
			}
		}
	}
	
	mapPath = Header.MapImage;

	bHasValidImage = ImageCheck();

	if( mapPath == "" || !bHasValidImage )
	{
		// temp until we get the real screen shots to display
		mapPath = "img:///UILibrary_Common.Xcom_default";
	}
	else
	{
		mapPath = "img:///"$mapPath;
	}

	//Image
	myValue.Type = AS_String;
	myValue.s = mapPath;
	myArray.AddItem(myValue);

	//Date
	myValue.s = strDate;
	myArray.AddItem(myValue);

	//Name
	myValue.s = strName;
	myArray.AddItem(myValue);

	//Mission
	myValue.s = strMission;
	myArray.AddItem(myValue);

	//accept Label
	myValue.s = GetAcceptLabel(bIsNewSave);
	AcceptButton.SetText(myValue.s);
	myArray.AddItem(myValue);

	//delete label
	myValue.s = m_sDeleteLabel;
	myArray.AddItem(myValue);
	DeleteButton.SetText(myValue.s);

	//rename label
	myValue.s = bIsSaving? m_sRenameLabel: " ";
	myArray.AddItem(myValue);

	Invoke("updateData", myArray);
}

simulated function string FormatTime( string HeaderTime )
{
	local string FormattedTime;

	// HeaderTime is in 24h format
	FormattedTime = HeaderTime;
	if( GetLanguage() == "INT" && !`GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK))
	{
		FormattedTime = `ONLINEEVENTMGR.FormatTimeStampFor12HourClock(FormattedTime);
	}

	FormattedTime = Repl(FormattedTime, "\n", " - ");

	return FormattedTime;
}