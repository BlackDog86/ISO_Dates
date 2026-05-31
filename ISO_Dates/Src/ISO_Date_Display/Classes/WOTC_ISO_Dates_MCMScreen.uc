class WOTC_ISO_Dates_MCMScreen extends Object config(XcomWOTC_ISO_Dates);

var config int VERSION_CFG;

var localized string ModName;
var localized string PageTitle;
var localized string GroupHeader;

`include(ISO_Date_Display\Src\ModConfigMenuAPI\MCM_API_Includes.uci)

`MCM_API_AutoCheckBoxVars(TWENTY_FOUR_HOUR_CLOCK);
`MCM_API_AutoCheckBoxVars(TWENTY_FOUR_HOUR_CLOCK_ON_GEOSCAPE);
`MCM_API_AutoCheckBoxVars(SHOW_MISSION_LOCATION_ON_SAVE_LOAD);
`MCM_API_AutoCheckBoxVars(USE_SOURCE_TIMEZONE_WHEN_FLYING);
`MCM_API_AutoCheckBoxVars(USE_DESTINATION_TIMEZONE_WHEN_FLYING);
`MCM_API_AutoCheckBoxVars(IGNORE_TIMEZONE_WHEN_FLYING);

`include(ISO_Date_Display\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

`MCM_API_AutoCheckBoxFns(TWENTY_FOUR_HOUR_CLOCK, 1);
`MCM_API_AutoCheckBoxFns(TWENTY_FOUR_HOUR_CLOCK_ON_GEOSCAPE, 1);
`MCM_API_AutoCheckBoxFns(SHOW_MISSION_LOCATION_ON_SAVE_LOAD, 1);
`MCM_API_AutoCheckBoxFns(USE_SOURCE_TIMEZONE_WHEN_FLYING, 1);
`MCM_API_AutoCheckBoxFns(USE_DESTINATION_TIMEZONE_WHEN_FLYING, 1);
`MCM_API_AutoCheckBoxFns(IGNORE_TIMEZONE_WHEN_FLYING, 1);

event OnInit(UIScreen Screen)
{
	`MCM_API_Register(Screen, ClientModCallback);
}

//Simple one group framework code
simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup Group;

	LoadSavedSettings();
	Page = ConfigAPI.NewSettingsPage(ModName);
	Page.SetPageTitle(PageTitle);
	Page.SetSaveHandler(SaveButtonClicked);
	
	//Uncomment to enable reset
	Page.EnableResetButton(ResetButtonClicked);

	Group = Page.AddGroup('Group', GroupHeader);

	`MCM_API_AutoAddCheckBox(Group, TWENTY_FOUR_HOUR_CLOCK);
	`MCM_API_AutoAddCheckBox(Group, TWENTY_FOUR_HOUR_CLOCK_ON_GEOSCAPE);
	`MCM_API_AutoAddCheckBox(Group, SHOW_MISSION_LOCATION_ON_SAVE_LOAD);
	`MCM_API_AutoAddCheckBox(Group, USE_SOURCE_TIMEZONE_WHEN_FLYING);
	`MCM_API_AutoAddCheckBox(Group, USE_DESTINATION_TIMEZONE_WHEN_FLYING);
	`MCM_API_AutoAddCheckBox(Group, IGNORE_TIMEZONE_WHEN_FLYING);

	Page.ShowSettings();
}

simulated function LoadSavedSettings()
{
	TWENTY_FOUR_HOUR_CLOCK = `GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK);
	TWENTY_FOUR_HOUR_CLOCK_ON_GEOSCAPE = `GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK_ON_GEOSCAPE);
	SHOW_MISSION_LOCATION_ON_SAVE_LOAD = `GETMCMVAR(SHOW_MISSION_LOCATION_ON_SAVE_LOAD);
	USE_SOURCE_TIMEZONE_WHEN_FLYING = `GETMCMVAR(USE_SOURCE_TIMEZONE_WHEN_FLYING);
	USE_DESTINATION_TIMEZONE_WHEN_FLYING = `GETMCMVAR(USE_DESTINATION_TIMEZONE_WHEN_FLYING);
	IGNORE_TIMEZONE_WHEN_FLYING = `GETMCMVAR(IGNORE_TIMEZONE_WHEN_FLYING);
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	`MCM_API_AutoReset(TWENTY_FOUR_HOUR_CLOCK);
	`MCM_API_AutoReset(TWENTY_FOUR_HOUR_CLOCK_ON_GEOSCAPE);
	`MCM_API_AutoReset(SHOW_MISSION_LOCATION_ON_SAVE_LOAD);
	`MCM_API_AutoReset(USE_SOURCE_TIMEZONE_WHEN_FLYING);
	`MCM_API_AutoReset(USE_DESTINATION_TIMEZONE_WHEN_FLYING);
	`MCM_API_AutoReset(IGNORE_TIMEZONE_WHEN_FLYING);

}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	VERSION_CFG = `MCM_CH_GetCompositeVersion();
	SaveConfig();	
	class'CHHelpers'.default.bForce24hClock = `GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK_ON_GEOSCAPE);
	class'CHHelpers'.default.bForce24hClockLeadingZero = `GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK_ON_GEOSCAPE);	
	class'CHHelpers'.default.bForceUTCAtAllTimes = `GETMCMVAR(IGNORE_TIMEZONE_WHEN_FLYING);
	class'CHHelpers'.default.bUseSourceTimeZoneWhenFlying = `GETMCMVAR(USE_SOURCE_TIMEZONE_WHEN_FLYING);	
	class'CHHelpers'.default.bUseDestinationTimeZoneWhenFlying = `GETMCMVAR(USE_DESTINATION_TIMEZONE_WHEN_FLYING);

}
