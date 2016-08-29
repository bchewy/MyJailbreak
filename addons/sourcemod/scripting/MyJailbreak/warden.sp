/*
 * MyJailbreak - Warden Plugin.
 * by: shanapu
 * https://github.com/shanapu/MyJailbreak/
 *
 * This file is part of the MyJailbreak SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */


/******************************************************************************
                   STARTUP
******************************************************************************/


//Includes
#include <myjailbreak> //... all other includes in myjailbreak.inc
#include <warden>


//Compiler Options
#pragma semicolon 1
#pragma newdecls required


//Console Variables
ConVar gc_bPlugin;
ConVar gc_bVote;
ConVar gc_bStayWarden;
ConVar gc_bBecomeWarden;
ConVar gc_bChooseRandom;
ConVar gc_bSounds;
ConVar gc_bOverlays;
ConVar gc_sWarden;
ConVar gc_sUnWarden;
ConVar gc_sModelPathWarden;
ConVar gc_bModel;
ConVar gc_bBetterNotes;
ConVar g_bMenuClose;
ConVar gc_sCustomCommand;
ConVar gc_fRandomTimer;


//Booleans
bool IsLR = false;


//Integers
int g_iWarden = -1;
int g_iTempWarden[MAXPLAYERS+1] = -1;
int g_iVoteCount;
int g_iBeamSprite = -1;
int g_iHaloSprite = -1;
int g_iSmokeSprite;
int g_iLastButtons[MAXPLAYERS+1];
int g_iColors[8][4] = 
{
	{255,255,255,255},  //white
	{255,0,0,255},  //red
	{20,255,20,255},  //green
	{0,65,255,255},  //blue
	{255,255,0,255},  //yellow
	{0,255,255,255},  //cyan
	{255,0,255,255},  //magenta
	{255,80,0,255}  //orange
};


//Handles
Handle gF_OnWardenCreated;
Handle gF_OnWardenRemoved;
Handle gF_OnWardenCreatedByUser;
Handle gF_OnWardenCreatedByAdmin;
Handle gF_OnWardenDisconnected;
Handle gF_OnWardenDeath;
Handle gF_OnWardenRemovedBySelf;
Handle gF_OnWardenRemovedByAdmin;
Handle RandomTimer;


//Strings
char g_sHasVoted[1500];
char g_sModelPathPrevious[256];
char g_sModelPathWarden[256];
char g_sUnWarden[256];
char g_sWarden[256];
char g_sCustomCommand[64];
char g_sMyJBLogFile[PLATFORM_MAX_PATH];


//Modules
#include "MyJailbreak/Modules/Warden/mute.sp"
#include "MyJailbreak/Modules/Warden/bulletsparks.sp"
#include "MyJailbreak/Modules/Warden/countdown.sp"
#include "MyJailbreak/Modules/Warden/math.sp"
#include "MyJailbreak/Modules/Warden/disarm.sp"
#include "MyJailbreak/Modules/Warden/noblock.sp"
#include "MyJailbreak/Modules/Warden/celldoors.sp"
#include "MyJailbreak/Modules/Warden/extendtime.sp"
#include "MyJailbreak/Modules/Warden/friendlyfire.sp"
#include "MyJailbreak/Modules/Warden/reminder.sp"
#include "MyJailbreak/Modules/Warden/randomkill.sp"
#include "MyJailbreak/Modules/Warden/handcuffs.sp"
#include "MyJailbreak/Modules/Warden/backstab.sp"
#include "MyJailbreak/Modules/Warden/gundrop.sp"
#include "MyJailbreak/Modules/Warden/marker.sp"
#include "MyJailbreak/Modules/Warden/icon.sp"
#include "MyJailbreak/Modules/Warden/color.sp"
#include "MyJailbreak/Modules/Warden/laser.sp"
#include "MyJailbreak/Modules/Warden/painter.sp"
#include "MyJailbreak/Modules/Warden/rebel.sp"
#include "MyJailbreak/Modules/Warden/counter.sp"


//Info
public Plugin myinfo = {
	name = "MyJailbreak - Warden",
	author = "shanapu, ecca, ESKO & .#zipcore",
	description = "Jailbreak Warden script",
	version = PLUGIN_VERSION,
	url = URL_LINK
};


//Start
public void OnPluginStart() 
{
	//Translation
	LoadTranslations("MyJailbreak.Warden.phrases");
	
	
	//Client commands
	RegConsoleCmd("sm_w", Command_BecomeWarden, "Allows the player taking the charge over prisoners");
	RegConsoleCmd("sm_warden", Command_BecomeWarden, "Allows the player taking the charge over prisoners");
	RegConsoleCmd("sm_uw", Command_ExitWarden, "Allows the player to retire from the position");
	RegConsoleCmd("sm_unwarden", Command_ExitWarden, "Allows the player to retire from the position");
	RegConsoleCmd("sm_hg", Command_BecomeWarden, "Allows the player taking the charge over prisoners");
	RegConsoleCmd("sm_headguard", Command_BecomeWarden, "Allows the player taking the charge over prisoners");
	RegConsoleCmd("sm_uhg", Command_ExitWarden, "Allows the player to retire from the position");
	RegConsoleCmd("sm_unheadguard", Command_ExitWarden, "Allows the player to retire from the position");
	RegConsoleCmd("sm_com", Command_BecomeWarden, "Allows the player taking the charge over prisoners");
	RegConsoleCmd("sm_commander", Command_BecomeWarden, "Allows the player taking the charge over prisoners");
	RegConsoleCmd("sm_uc", Command_ExitWarden, "Allows the player to retire from the position");
	RegConsoleCmd("sm_uncommander", Command_ExitWarden, "Allows the player to retire from the position");
	RegConsoleCmd("sm_vw", Command_VoteWarden, "Allows the player to vote to retire Warden");
	RegConsoleCmd("sm_votewarden", Command_VoteWarden, "Allows the player to vote to retire Warden");
	RegConsoleCmd("sm_vetowarden", Command_VoteWarden, "Allows the player to vote to retire Warden");
	
	
	//Admin commands
	RegAdminCmd("sm_sw", AdminCommand_SetWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_setwarden", AdminCommand_SetWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_rw", AdminCommand_RemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_fw", AdminCommand_RemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_firewarden", AdminCommand_RemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_removewarden", AdminCommand_RemoveWarden, ADMFLAG_GENERIC);
	
	
	//Forwards
	gF_OnWardenCreated = CreateGlobalForward("warden_OnWardenCreated", ET_Ignore, Param_Cell);
	gF_OnWardenRemoved = CreateGlobalForward("warden_OnWardenRemoved", ET_Ignore, Param_Cell);
	gF_OnWardenCreatedByUser = CreateGlobalForward("warden_OnWardenCreatedByUser", ET_Ignore, Param_Cell);
	gF_OnWardenCreatedByAdmin = CreateGlobalForward("warden_OnWardenCreatedByAdmin", ET_Ignore, Param_Cell);
	gF_OnWardenDisconnected = CreateGlobalForward("warden_OnWardenDisconnected", ET_Ignore, Param_Cell);
	gF_OnWardenDeath = CreateGlobalForward("warden_OnWardenDeath", ET_Ignore, Param_Cell);
	gF_OnWardenRemovedBySelf = CreateGlobalForward("warden_OnWardenRemovedBySelf", ET_Ignore, Param_Cell);
	gF_OnWardenRemovedByAdmin = CreateGlobalForward("warden_OnWardenRemovedByAdmin", ET_Ignore, Param_Cell);
	
	
	//AutoExecConfig
	AutoExecConfig_SetFile("Warden", "MyJailbreak");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_warden_version", PLUGIN_VERSION, "The version of this MyJailbreak SourceMod plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gc_bPlugin = AutoExecConfig_CreateConVar("sm_warden_enable", "1", "0 - disabled, 1 - enable this MyJailbreak SourceMod plugin", _, true,  0.0, true, 1.0);
	gc_sCustomCommand = AutoExecConfig_CreateConVar("sm_warden_cmd", "simon", "Set your custom chat command for become warden. no need for sm_ or !");
	gc_bBecomeWarden = AutoExecConfig_CreateConVar("sm_warden_become", "1", "0 - disabled, 1 - enable !w / !warden - player can choose to be warden. If disabled you should need sm_warden_choose_random 1", _, true,  0.0, true, 1.0);
	gc_bChooseRandom = AutoExecConfig_CreateConVar("sm_warden_choose_random", "0", "0 - disabled, 1 - enable pick random warden if there is still no warden after sm_warden_choose_time", _, true,  0.0, true, 1.0);
	gc_fRandomTimer = AutoExecConfig_CreateConVar("sm_warden_choose_time", "45.0", "Time in seconds a random warden will picked when no warden was set. need sm_warden_choose_random 1", _, true,  1.0);
	gc_bVote = AutoExecConfig_CreateConVar("sm_warden_vote", "1", "0 - disabled, 1 - enable player vote against warden", _, true,  0.0, true, 1.0);
	gc_bStayWarden = AutoExecConfig_CreateConVar("sm_warden_stay", "1", "0 - disabled, 1 - enable warden stay after round end", _, true,  0.0, true, 1.0);
	gc_bBetterNotes = AutoExecConfig_CreateConVar("sm_warden_better_notifications", "1", "0 - disabled, 1 - Will use hint and center text", _, true, 0.0, true, 1.0);
	gc_bModel = AutoExecConfig_CreateConVar("sm_warden_model", "1", "0 - disabled, 1 - enable warden model", 0, true, 0.0, true, 1.0);
	gc_sModelPathWarden = AutoExecConfig_CreateConVar("sm_warden_model_path", "models/player/custom_player/legacy/security/security.mdl", "Path to the model for warden.");
	gc_bSounds = AutoExecConfig_CreateConVar("sm_warden_sounds_enable", "1", "0 - disabled, 1 - enable sounds ", _, true,  0.0, true, 1.0);
	gc_sWarden = AutoExecConfig_CreateConVar("sm_warden_sounds_warden", "music/MyJailbreak/warden.mp3", "Path to the soundfile which should be played for a int warden.");
	gc_sUnWarden = AutoExecConfig_CreateConVar("sm_warden_sounds_unwarden", "music/MyJailbreak/unwarden.mp3", "Path to the soundfile which should be played when there is no warden anymore.");
	gc_bOverlays = AutoExecConfig_CreateConVar("sm_warden_overlays_enable", "1", "0 - disabled, 1 - enable overlays", _, true,  0.0, true, 1.0);
	
	
	//Warden module
	Mute_OnPluginStart();
	Disarm_OnPluginStart();
	BulletSparks_OnPluginStart();
	Countdown_OnPluginStart();
	Math_OnPluginStart();
	NoBlock_OnPluginStart();
	CellDoors_OnPluginStart();
	ExtendTime_OnPluginStart();
	FriendlyFire_OnPluginStart();
	Reminder_OnPluginStart();
	RandomKill_OnPluginStart();
	HandCuffs_OnPluginStart();
	BackStab_OnPluginStart();
	Marker_OnPluginStart();
	GunDropPrevention_OnPluginStart();
	Icon_OnPluginStart();
	Color_OnPluginStart();
	Laser_OnPluginStart();
	Painter_OnPluginStart();
	MarkRebel_OnPluginStart();
	Counter_OnPluginStart();
	
	
	//AutoExecConfig
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	
	//Hooks
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_poststart", Event_PostRoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_end", Event_RoundEnd);
	HookConVarChange(gc_sModelPathWarden, OnSettingChanged);
	HookConVarChange(gc_sUnWarden, OnSettingChanged);
	HookConVarChange(gc_sWarden, OnSettingChanged);
	
	
	//FindConVar
	g_bMenuClose = FindConVar("sm_menu_close");
	gc_sWarden.GetString(g_sWarden, sizeof(g_sWarden));
	gc_sUnWarden.GetString(g_sUnWarden, sizeof(g_sUnWarden));
	gc_sModelPathWarden.GetString(g_sModelPathWarden, sizeof(g_sModelPathWarden));
	gc_sCustomCommand.GetString(g_sCustomCommand , sizeof(g_sCustomCommand));
	
	
	//Set directory for LogFile - must be created before
	SetLogFile(g_sMyJBLogFile, "MyJB");
}


//ConVarChange for Strings
public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == gc_sWarden)
	{
		strcopy(g_sWarden, sizeof(g_sWarden), newValue);
		if(gc_bSounds.BoolValue) PrecacheSoundAnyDownload(g_sWarden);
	}
	else if(convar == gc_sUnWarden)
	{
		strcopy(g_sUnWarden, sizeof(g_sUnWarden), newValue);
		if(gc_bSounds.BoolValue) PrecacheSoundAnyDownload(g_sUnWarden);
	}
	else if(convar == gc_sModelPathWarden)
	{
		strcopy(g_sModelPathWarden, sizeof(g_sModelPathWarden), newValue);
		if(gc_bModel.BoolValue) PrecacheModel(g_sModelPathWarden);
	}
	else if(convar == gc_sCustomCommand)
	{
		strcopy(g_sCustomCommand, sizeof(g_sCustomCommand), newValue);
		char sBufferCMD[64];
		Format(sBufferCMD, sizeof(sBufferCMD), "sm_%s", g_sCustomCommand);
		if(GetCommandFlags(sBufferCMD) == INVALID_FCVAR_FLAGS)  //if command not already exist
			RegConsoleCmd(sBufferCMD, Command_BecomeWarden, "Allows the player taking the charge over prisoners");
	}
}


//Initialize Plugin
public void OnConfigsExecuted()
{
	Math_OnConfigsExecuted();
	RandomKill_OnConfigsExecuted();
	
	char sBufferCMD[64];
	Format(sBufferCMD, sizeof(sBufferCMD), "sm_%s", g_sCustomCommand);
	if(GetCommandFlags(sBufferCMD) == INVALID_FCVAR_FLAGS)  //if command not already exist
		RegConsoleCmd(sBufferCMD, Command_BecomeWarden, "Allows the player taking the charge over prisoners");
}


/******************************************************************************
                   COMMANDS
******************************************************************************/


//Become Warden
public Action Command_BecomeWarden(int client, int args)
{
	if(gc_bPlugin.BoolValue)  //"sm_warden_enable" "1"
	{
		if(g_iWarden == -1)  //Is there already a warden
		{
			if (gc_bBecomeWarden.BoolValue)  //"sm_warden_become" "1"
			{
				if (GetClientTeam(client) == CS_TEAM_CT)  //Is player a guard
				{
					if (IsPlayerAlive(client))  //Alive?
					{
						SetTheWarden(client);
						Forward_OnWardenCreatedByUser(client);
					}
					else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_playerdead");
				}
				else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_ctsonly");
			}
			else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_nobecome", g_iWarden);
		}
		else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_exist", g_iWarden);
	}
	else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_disabled");
	return Plugin_Handled;
}


//Exit / Retire Warden
public Action Command_ExitWarden(int client, int args) 
{
	if(gc_bPlugin.BoolValue)  //"sm_warden_enable" "1"
	{
		if(IsClientWarden(client))  //Is client the warden
		{
			Forward_OnWardenRemovedBySelf(client);
			RemoveTheWarden();
			
			CPrintToChatAll("%t %t", "warden_tag" , "warden_retire", client);
			if(gc_bBetterNotes.BoolValue)
			{
				PrintCenterTextAll("%t", "warden_retire_nc", client);
			}
		}
		else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_notwarden");
	}
	else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_disabled");
	return Plugin_Handled;
}


//Voting against Warden
public Action Command_VoteWarden(int client,int args)
{
	if(gc_bPlugin.BoolValue)  //"sm_warden_enable" "1"
	{
		if(gc_bVote.BoolValue)  //"sm_warden_vote" "1"
		{
			char steamid[64];
			GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));  //Get client steam ID
			if(g_iWarden != -1)
			{
				if (StrContains(g_sHasVoted, steamid, true) == -1)  //Check steam ID has already voted
				{
					int playercount = (GetClientCount(true) / 2);
					g_iVoteCount++;
					int Missing = playercount - g_iVoteCount + 1;
					Format(g_sHasVoted, sizeof(g_sHasVoted), "%s,%s", g_sHasVoted, steamid);
					
					if (g_iVoteCount > playercount)
					{
						if(ActiveLogging()) LogToFileEx(g_sMyJBLogFile, "Player %L was kick as warden by voting", g_iWarden);
						RemoveTheWarden();
					}
					else CPrintToChatAll("%t %t", "warden_tag" , "warden_need", Missing, client);
				}
				else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_voted");
			}
			else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_noexist");
		}
		else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_voting");
	}
	else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_disabled");
	return Plugin_Handled;
}


//Remove Warden for Admins
public Action AdminCommand_RemoveWarden(int client, int args)
{
	if(gc_bPlugin.BoolValue)  //"sm_warden_enable" "1"
	{
		if(g_iWarden != -1)  //Is there a warden to remove
		{
			CPrintToChatAll("%t %t", "warden_tag" , "warden_removed", client, g_iWarden);  // if client is console !=
			if(gc_bBetterNotes.BoolValue) PrintCenterTextAll("%t", "warden_removed_nc", client, g_iWarden);
			
			if(ActiveLogging()) LogToFileEx(g_sMyJBLogFile, "Admin %L removed player %L as warden", client, g_iWarden);
			
			RemoveTheWarden();
			Forward_OnWardenRemovedByAdmin(client);
		}
	}
	return Plugin_Handled;
}


//Set new Warden for Admins
public Action AdminCommand_SetWarden(int client,int args)
{
	if(gc_bPlugin.BoolValue)  //"sm_warden_enable" "1"
	{
		Menu_SetWarden(client);
	}
	return Plugin_Handled;
}


/******************************************************************************
                   EVENTS
******************************************************************************/


//Warden Died
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));  //Get the dead clients id
	
	if(IsClientWarden(client))  //The Warden is dead
	{
		Forward_OnWardenDeath(client);
		Forward_OnWardenRemoved(client);
		
		CPrintToChatAll("%t %t", "warden_tag" , "warden_dead", client);
		if(gc_bBetterNotes.BoolValue)
		{
			PrintCenterTextAll("%t", "warden_dead_nc", client);
		}
		
		if(gc_bSounds.BoolValue)
		{
			EmitSoundToAllAny(g_sUnWarden);
		}
		
		if (RandomTimer != null)
		KillTimer(RandomTimer);
		
		RandomTimer = null;
		RandomTimer = CreateTimer(gc_fRandomTimer.FloatValue, Timer_ChooseRandom);
		
		g_iWarden = -1;
	}
}


//Warden change Team
public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));  //Get the clients id
	
	if(IsClientWarden(client))  //The Warden changed team
	{
		Forward_OnWardenDeath(client);
		RemoveTheWarden();
		
		CPrintToChatAll("%t %t", "warden_tag" , "warden_retire", client);
		if(gc_bBetterNotes.BoolValue)
		{
			PrintCenterTextAll("%t", "warden_retire_nc", client);
		}
	}
}


//Round Start Post
public void Event_PostRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(gc_bPlugin.BoolValue)
	{
		if((g_iWarden == -1) && gc_bBecomeWarden.BoolValue)
		{
			RandomTimer = CreateTimer(gc_fRandomTimer.FloatValue, Timer_ChooseRandom);
			CPrintToChatAll("%t %t", "warden_tag" , "warden_nowarden");
			if(gc_bBetterNotes.BoolValue)
			{
				PrintCenterTextAll("%t", "warden_nowarden_nc");
			}
		}
	}
}


//Round Start Post
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!gc_bPlugin.BoolValue)
	{
		if(g_iWarden != -1)
		{
			CreateTimer(0.1, Timer_RemoveColor, g_iWarden);
			SetEntityModel(g_iWarden, g_sModelPathPrevious);
			Forward_OnWardenRemoved(g_iWarden);
			g_iWarden = -1;
		}
	}
	char EventDay[64];
	GetEventDayName(EventDay);
	
	if(!StrEqual(EventDay, "none", false) || !gc_bStayWarden.BoolValue)
	{
		if(g_iWarden != -1)
		{
			CreateTimer( 0.1, Timer_RemoveColor, g_iWarden);
			SetEntityModel(g_iWarden, g_sModelPathPrevious);
			Forward_OnWardenRemoved(g_iWarden);
			g_iWarden = -1;
			
		}
	}
	if(g_iWarden != -1)
	{
		if(gc_bModel.BoolValue) SetEntityModel(g_iWarden, g_sModelPathWarden);
	}
	IsLR = false;
}


//Round End
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	IsLR = false;
}


/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/


//Prepare Plugin & modules
public void OnMapStart()
{
	Countdown_OnMapStart();
	Math_OnMapStart();
	HandCuffs_OnMapStart();
	Marker_OnMapStart();
	Reminder_OnMapStart();
	Icon_OnMapStart();
	Laser_OnMapStart();
	Painter_OnMapStart();
	
	if(gc_bSounds.BoolValue)
	{
		PrecacheSoundAnyDownload(g_sWarden);
		PrecacheSoundAnyDownload(g_sUnWarden);
	}
	
	g_iVoteCount = 0;
	
	PrecacheModel(g_sModelPathWarden);
	g_iSmokeSprite = PrecacheModel("materials/sprites/steam1.vmt");
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	PrecacheSound(SOUND_THUNDER, true);
}


//Prepare client for Plugin & modules
public void OnClientPutInServer(int client)
{
	BulletSparks_OnClientPutInServer(client);
	HandCuffs_OnClientPutInServer(client);
	BackStab_OnClientPutInServer(client);
	Laser_OnClientPutInServer(client);
	Painter_OnClientPutInServer(client);
}


//Warden disconnect
public void OnClientDisconnect(int client)
{
	if(IsClientWarden(client))
	{
		CPrintToChatAll("%t %t", "warden_tag" , "warden_disconnected", client);
		if(gc_bBetterNotes.BoolValue)
		{
			PrintCenterTextAll("%t", "warden_disconnected_nc", client);
		}
		
		Forward_OnWardenRemoved(client);
		Forward_OnWardenDisconnected(client);
		
		if(gc_bSounds.BoolValue)
		{
			EmitSoundToAllAny(g_sUnWarden);
		}
		
		g_iWarden = -1;
	}
	
	Painter_OnClientDisconnect(client);
	HandCuffs_OnClientDisconnect(client);
	Icon_OnClientDisconnect(client);
}


//Close open timer & reset warden/module
public void OnMapEnd()
{
	if (g_iWarden != -1)
	{
		CreateTimer(0.1, Timer_RemoveColor, g_iWarden);
		Forward_OnWardenRemoved(g_iWarden);
		g_iWarden = -1;
	}
	
	Math_OnMapEnd();
	Mute_OnMapEnd();
	Countdown_OnMapEnd();
	Reminder_OnMapEnd();
	HandCuffs_OnMapEnd();
	Marker_OnMapEnd();
	Laser_OnMapEnd();
	Painter_OnMapEnd();
}


//When a last request is available
public int OnAvailableLR(int Announced)
{
	IsLR = true;
	
	GunDropPrevention_OnAvailableLR(Announced);
	Mute_OnAvailableLR(Announced);
	HandCuffs_OnAvailableLR(Announced);
}


// Check Keyboard Input for modules
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(IsClientWarden(client) && gc_bPlugin.BoolValue)
	{
		HandCuffs_OnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon);
		Marker_OnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon);
		Laser_OnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon);
		Painter_OnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon);
	}
	return Plugin_Continue;
}


/******************************************************************************
                   FUNCTIONS
******************************************************************************/


//Set a new warden
void SetTheWarden(int client)
{
	if(gc_bPlugin.BoolValue)
	{
		CPrintToChatAll("%t %t", "warden_tag" , "warden_new", client);
		if(gc_bBetterNotes.BoolValue) PrintCenterTextAll("%t", "warden_new_nc", client);
		
		g_iWarden = client;
		
		GetEntPropString(client, Prop_Data, "m_ModelName", g_sModelPathPrevious, sizeof(g_sModelPathPrevious));
		if(gc_bModel.BoolValue)
		{
			SetEntityModel(client, g_sModelPathWarden);
		}
		SetClientListeningFlags(client, VOICE_NORMAL);
		Forward_OnWardenCreated(client);
		
		if(gc_bSounds.BoolValue)
		{
			EmitSoundToAllAny(g_sWarden);
		}
		if (RandomTimer != null)
		KillTimer(RandomTimer);
		
		RandomTimer = null;
	}
	else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_disabled");
}


//Remove the current warden
void RemoveTheWarden()
{
	CreateTimer( 0.1, Timer_RemoveColor, g_iWarden);
	SetEntityModel(g_iWarden, g_sModelPathPrevious);
	if (RandomTimer != null)
		KillTimer(RandomTimer);
	
	RandomTimer = null;
	RandomTimer = CreateTimer(gc_fRandomTimer.FloatValue, Timer_ChooseRandom);
	
	Forward_OnWardenRemoved(g_iWarden);
	
	if(gc_bSounds.BoolValue)
	{
		EmitSoundToAllAny(g_sUnWarden);
	}
	
	g_iVoteCount = 0;
	Format(g_sHasVoted, sizeof(g_sHasVoted), "");
	g_sHasVoted[0] = '\0';
	
	g_iWarden = -1;
}


/******************************************************************************
                   MENUS
******************************************************************************/


//Admin set (new) Warden menu
void Menu_SetWarden(int client)
{
	char info1[255];
	Menu menu = CreateMenu(Handler_SetWarden);
	Format(info1, sizeof(info1), "%T", "warden_choose", client);
	menu.SetTitle(info1);
	LoopValidClients(i, true, false)
	{
		if(GetClientTeam(i) == CS_TEAM_CT && IsClientWarden(i) == false)
		{
			char userid[11];
			char username[MAX_NAME_LENGTH];
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			Format(username, sizeof(username), "%N", i);
			menu.AddItem(userid,username);
		}
	}
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client,MENU_TIME_FOREVER);
}


//Handler set (new) Warden menu with overwrite/remove query
public int Handler_SetWarden(Menu menu, MenuAction action, int client, int Position)
{
	if(action == MenuAction_Select)
	{
		char Item[11];
		menu.GetItem(Position,Item,sizeof(Item));
		
		LoopValidClients(i, true, false)
		{
			if(GetClientTeam(i) == CS_TEAM_CT && IsClientWarden(i) == false)
			{
				char info4[255], info2[255], info3[255];
				int userid = GetClientUserId(i);
				if(userid == StringToInt(Item))
				{
					if(g_iWarden != -1)  // if(g_iWarden != -1)
					{
						g_iTempWarden[client] = userid;
						Menu menu1 = CreateMenu(Handler_SetWardenOverwrite);
						Format(info4, sizeof(info4), "%T", "warden_remove", client);
						menu1.SetTitle(info4);
						Format(info3, sizeof(info3), "%T", "warden_yes", client);
						Format(info2, sizeof(info2), "%T", "warden_no", client);
						menu1.AddItem("1", info3);
						menu1.AddItem("0", info2);
						menu1.ExitBackButton = true;
						menu1.ExitButton = true;
						menu1.Display(client,MENU_TIME_FOREVER);
					}
					else
					{
						SetTheWarden(i);
						Forward_OnWardenCreatedByAdmin(i);
					}
				}
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(Position == MenuCancel_ExitBack) 
		{
			FakeClientCommand(client, "sm_menu");
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}


//Handler overwrite/remove query menu
public int Handler_SetWardenOverwrite(Menu menu, MenuAction action, int client, int Position)
{
	if(action == MenuAction_Select)
	{
		char Item[11];
		menu.GetItem(Position,Item,sizeof(Item));
		int choice = StringToInt(Item);
		if(choice == 1)
		{
			int newwarden = GetClientOfUserId(g_iTempWarden[client]);
			if (g_iWarden != -1)CPrintToChatAll("%t %t", "warden_tag" , "warden_removed", client, g_iWarden);
			
			if(ActiveLogging()) LogToFileEx(g_sMyJBLogFile, "Admin %L kick player %L warden and set %L as new", client, g_iWarden, newwarden);
			
			RemoveTheWarden();
			SetTheWarden(newwarden);
			Forward_OnWardenCreatedByAdmin(newwarden);
		}
		if(g_bMenuClose != null)
		{
			if(!g_bMenuClose)
			{
				FakeClientCommand(client, "sm_menu");
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(Position == MenuCancel_ExitBack) 
		{
			FakeClientCommand(client, "sm_menu");
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}


/******************************************************************************
                   TIMER
******************************************************************************/


//Choose a random Warden after a defined time
public Action Timer_ChooseRandom(Handle timer, Handle pack)
{
	if(gc_bPlugin.BoolValue)
	{
		if(g_iWarden == -1)
		{
			if(gc_bChooseRandom.BoolValue)
			{
				int i = GetRandomPlayer(CS_TEAM_CT);
				if(i > 0)
				{
					CPrintToChatAll("%t %t", "warden_tag", "warden_randomwarden"); 
					SetTheWarden(i);
				}
			}
		}
	}
	if (RandomTimer != null)
		KillTimer(RandomTimer);
			
	RandomTimer = null;
}


/******************************************************************************
                   STOCKS
******************************************************************************/


stock bool IsClientWarden(int client)
{
	if(client != g_iWarden)
	{
		return false;
	}
	return true;
}


/******************************************************************************
                   NATIVES
******************************************************************************/


//Register Natives
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("warden_exist", Native_ExistWarden);
	CreateNative("warden_iswarden", Native_IsWarden);
	CreateNative("warden_set", Native_SetWarden);
	CreateNative("warden_removed", Native_RemoveWarden);
	CreateNative("warden_get", Native_GetWarden);
	
	RegPluginLibrary("warden");
	return APLRes_Success;
}


//Booleans Exist Warden
public int Native_ExistWarden(Handle plugin, int numParams)
{
	if(g_iWarden == -1)
	{
		return false;
	}
	return true;
}


//Booleans Is Client Warden
public int Native_IsWarden(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if(IsClientWarden(client))
		return true;
	
	return false;
}


//Set Client as Warden
public int Native_SetWarden(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if(g_iWarden == -1)
		SetTheWarden(client);
}


//Remove current Warden
public int Native_RemoveWarden(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if(IsClientWarden(client))
		RemoveTheWarden();
}


//Get Warden Client Index
public int Native_GetWarden(Handle plugin, int argc)
{
	return g_iWarden;
}


/******************************************************************************
                   FORWARDS CALL
******************************************************************************/


//New Warden was set (will fire all time - *ByUser *ByAdmin ...)
void Forward_OnWardenCreated(int client)
{
	Call_StartForward(gF_OnWardenCreated);
	Call_PushCell(client);
	Call_Finish();
	
	Icon_OnWardenCreation(client);
	Color_OnWardenCreation(client);
	Laser_OnWardenCreation(client);
	Painter_OnWardenCreation(client);
}


//New Warden was set (will only fire on set ByUser)
void Forward_OnWardenCreatedByUser(int client)
{
	Call_StartForward(gF_OnWardenCreatedByUser);
	Call_PushCell(client);
	Call_Finish();
}


//New Warden was set (will only fire on set ByAdmin)
void Forward_OnWardenCreatedByAdmin(int client)
{
	Call_StartForward(gF_OnWardenCreatedByAdmin);
	Call_PushCell(client);
	Call_Finish();
}


//Warden was removed (will fire all time - *BySelf *ByAdmin *Death ...)
void Forward_OnWardenRemoved(int client)
{
	Call_StartForward(gF_OnWardenRemoved);
	Call_PushCell(client);
	Call_Finish();
	
	Marker_OnWardenRemoved();
	Icon_OnWardenRemoved(client);
	Color_OnWardenRemoved(client);
	Laser_OnWardenRemoved(client);
	Painter_OnWardenRemoved(client);
}


//Warden was removed (will only fire on ByAdmin)
void Forward_OnWardenRemovedByAdmin(int client)
{
	Call_StartForward(gF_OnWardenRemovedByAdmin);
	Call_PushCell(client);
	Call_Finish();
}


//Warden was removed (will only fire on BySelf)
void Forward_OnWardenRemovedBySelf(int client)
{
	Call_StartForward(gF_OnWardenRemovedBySelf);
	Call_PushCell(client);
	Call_Finish();
}


//Warden was removed (will only fire on Disconnect)
void Forward_OnWardenDisconnected(int client)
{
	Call_StartForward(gF_OnWardenDisconnected);
	Call_PushCell(client);
	Call_Finish();
}


//Warden was removed (will only fire on Death)
void Forward_OnWardenDeath(int client)
{
	Call_StartForward(gF_OnWardenDeath);
	Call_PushCell(client);
	Call_Finish();
}