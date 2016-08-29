/*
 * MyJailbreak - Request Plugin.
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


//Compiler Options
#pragma semicolon 1
#pragma newdecls required


//Console Variables
ConVar gc_bPlugin;
ConVar gc_bSounds;


//Booleans
bool g_bHaveFreeDay[MAXPLAYERS+1];
bool IsRequest;
bool IsLR;


//Integers
int g_iKilledBy[MAXPLAYERS+1];
int g_iHasKilled[MAXPLAYERS+1];


//Handles
Handle RequestTimer;


//Float
float DeathOrigin[MAXPLAYERS+1][3];


//Modules
#include "MyJailbreak/Modules/Request/refuse.sp"
#include "MyJailbreak/Modules/Request/capitulation.sp"
#include "MyJailbreak/Modules/Request/heal.sp"
#include "MyJailbreak/Modules/Request/repeat.sp"
#include "MyJailbreak/Modules/Request/freekill.sp"
#include "MyJailbreak/Modules/Request/killreason.sp"
#include "MyJailbreak/Modules/Request/freedays.sp"


//Info
public Plugin myinfo = 
{
	name = "MyJailbreak - Request",
	author = "shanapu",
	description = "Requests - refuse, capitulation/pardon, heal",
	version = PLUGIN_VERSION,
	url = URL_LINK
}


//Start
public void OnPluginStart()
{
	// Translationw
	LoadTranslations("MyJailbreak.Warden.phrases");
	LoadTranslations("MyJailbreak.Request.phrases");
	
	
	//Client Commands
	RegConsoleCmd("sm_request", Command_RequestMenu, "Open the requests menu");
	
	
	//AutoExecConfig
	AutoExecConfig_SetFile("Request", "MyJailbreak");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_request_version", PLUGIN_VERSION, "The version of this MyJailbreak SourceMod plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gc_bPlugin = AutoExecConfig_CreateConVar("sm_request_enable", "1", "0 - disabled, 1 - enable Request Plugin");
	gc_bSounds = AutoExecConfig_CreateConVar("sm_request_sounds_enable", "1", "0 - disabled, 1 - enable sounds ", _, true,  0.0, true, 1.0);
	
	
	Refuse_OnPluginStart();
	Repeat_OnPluginStart();
	Heal_OnPluginStart();
	Capitulation_OnPluginStart();
	Freekill_OnPluginStart();
	KillReason_OnPluginStart();
	Freedays_OnPluginStart();
	
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	
	//Hooks
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
}



/******************************************************************************
                   COMMANDS
******************************************************************************/


public Action Command_RequestMenu(int client, int args)
{
	if(gc_bPlugin.BoolValue)
	{
		if (GetClientTeam(client) == CS_TEAM_T && IsValidClient(client,false,true))
		{
			Menu reqmenu = new Menu(Command_RequestMenuHandler);
			
			char menuinfo19[255], menuinfo20[255], menuinfo21[255], menuinfo22[255], menuinfo29[255];
			
			Format(menuinfo29, sizeof(menuinfo29), "%T", "request_menu_title", client);
			reqmenu.SetTitle(menuinfo29);
			
			if(gc_bFreeKill.BoolValue && (!IsPlayerAlive(client)))
			{
				Format(menuinfo19, sizeof(menuinfo19), "%T", "request_menu_freekill", client);
				reqmenu.AddItem("freekill", menuinfo19);
			}
			if(gc_bRefuse.BoolValue && (IsPlayerAlive(client)))
			{
				Format(menuinfo19, sizeof(menuinfo19), "%T", "request_menu_refuse", client);
				reqmenu.AddItem("refuse", menuinfo19);
			}
			if(gc_bCapitulation.BoolValue && (IsPlayerAlive(client)))
			{
				Format(menuinfo20, sizeof(menuinfo20), "%T", "request_menu_capitulation", client);
				reqmenu.AddItem("capitulation", menuinfo20);
			}
			if(gc_bRepeat.BoolValue && (IsPlayerAlive(client)))
			{
				Format(menuinfo21, sizeof(menuinfo21), "%T", "request_menu_repeat", client);
				reqmenu.AddItem("repeat", menuinfo21);
			}
			if(gc_bHeal.BoolValue && (IsPlayerAlive(client)))
			{
				Format(menuinfo22, sizeof(menuinfo22), "%T", "request_menu_heal", client);
				reqmenu.AddItem("heal", menuinfo22);
			}
			reqmenu.ExitButton = true;
			reqmenu.ExitBackButton = true;
			reqmenu.Display(client, MENU_TIME_FOREVER);
		}
		else CReplyToCommand(client, "%t %t", "request_tag", "request_notalivect");
	}
	return Plugin_Handled;
}


/******************************************************************************
                   EVENTS
******************************************************************************/


public void Event_RoundStart(Event event, char [] name, bool dontBroadcast)
{
	delete RequestTimer;
	
	IsRequest = false;
	
	IsLR = false;
	
	LoopClients(client)
	{
		g_iKilledBy[client] = 0;
		g_iHasKilled[client] = 0;
	}
}


//Round End
public void Event_RoundEnd(Event event, char[] name, bool dontBroadcast)
{
	IsLR = false;
}


public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int victimID = event.GetInt("userid"); // Get the dead user id
	int victim = GetClientOfUserId(victimID); // Get the dead clients id
	int attackerID = event.GetInt("attacker"); // Get the user clients id
	int attacker = GetClientOfUserId(attackerID); // Get the attacker clients id
	
	
	if(IsValidClient(attacker, true, false) && (attacker != victim))
	{
		g_iKilledBy[victim] = attackerID;
		g_iHasKilled[attacker] = victimID;
	}
}


/******************************************************************************
                   FORWARDS LISTENING
******************************************************************************/


public void OnMapStart()
{
	Refuse_OnMapStart();
	Capitulation_OnMapStart();
	Repeat_OnMapStart();
	Freedays_OnMapStart();
	
	IsLR = false;
}


public void OnConfigsExecuted()
{
	Refuse_OnConfigsExecuted();
	Capitulation_OnConfigsExecuted();
	Heal_OnConfigsExecuted();
	Repeat_OnConfigsExecuted();
	Freedays_OnConfigsExecuted();
}


public void OnClientPutInServer(int client)
{
	Refuse_OnClientPutInServer(client);
	Capitulation_OnClientPutInServer(client);
	Heal_OnClientPutInServer(client);
	Repeat_OnClientPutInServer(client);
	Freekill_OnClientPutInServer(client);
}


public void OnClientDisconnect(int client)
{
	Refuse_OnClientDisconnect(client);
	Heal_OnClientDisconnect(client);
	Repeat_OnClientDisconnect(client);
}


public int OnAvailableLR(int Announced)
{
	Capitulation_OnAvailableLR(Announced);
	IsLR = true;
}

/******************************************************************************
                   MENUS
******************************************************************************/


public int Command_RequestMenuHandler(Menu reqmenu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		
		reqmenu.GetItem(selection, info, sizeof(info));
		
		if ( strcmp(info,"refuse") == 0 ) 
		{
			FakeClientCommand(client, "sm_refuse");
		} 
		else if ( strcmp(info,"freekill") == 0 ) 
		{
			FakeClientCommand(client, "sm_freekill");
		} 
		else if ( strcmp(info,"repeat") == 0 ) 
		{
			FakeClientCommand(client, "sm_repeat");
		} 
		else if ( strcmp(info,"capitulation") == 0 ) 
		{
			FakeClientCommand(client, "sm_capitulation");
		} 
		else if ( strcmp(info,"heal") == 0 )
		{
			FakeClientCommand(client, "sm_heal");
		}
	}
	else if(action == MenuAction_Cancel) 
	{
		if(selection == MenuCancel_ExitBack) 
		{
			FakeClientCommand(client, "sm_menu");
		}
	}
	else if (action == MenuAction_End)
	{
		delete reqmenu;
	}
}


/******************************************************************************
                   TIMER
******************************************************************************/


public Action Timer_IsRequest(Handle timer, any client)
{
	IsRequest = false;
	RequestTimer = null;
	LoopClients(i) if(g_bFreeKilled[i]) g_bFreeKilled[i] = false;
}