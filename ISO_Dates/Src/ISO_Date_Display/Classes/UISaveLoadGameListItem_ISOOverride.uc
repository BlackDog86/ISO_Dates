class UISaveLoadGameListItem_ISOOverride extends UISaveLoadGameListItem config(DateTime)
	dependson(XComOnlineEventMgr);
	
	var config bool b24hClock;

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
	//11:41 PM ADVENT Patrol Area, Mexico City		Descriptions[5] - In-Game Time & Area

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
		strTime = saveDateArray[2] $'-'$ saveDateArray[0] $'-'$ saveDateArray[1] $' - '$ dateTimeArray[1]; // This is actually the date & time concatenated together
		strDate = strTime @ (Descriptions.Length >= 3 ? Descriptions[2] : ""); // This goes on the first line of the save/load box (Date + time + user save description)
		
		if (Descriptions.Length == 7) // We saved in a mission
			{
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
			strMission $= ' - '$ Descriptions[4];											// This is the final line in the save box (i.e in-game-date + operation name)
			}
		if (Descriptions.Length == 6) // We saved on the Geoscape
			{
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
			strMission $= ' - ' $ Descriptions[5];
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
	if( GetLanguage() == "INT" && !b24hClock )
	{
		FormattedTime = `ONLINEEVENTMGR.FormatTimeStampFor12HourClock(FormattedTime);
	}

	FormattedTime = Repl(FormattedTime, "\n", " - ");

	return FormattedTime;
}