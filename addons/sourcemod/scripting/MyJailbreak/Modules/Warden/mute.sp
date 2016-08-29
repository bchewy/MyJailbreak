/*
 * MyJailbreak - Warden - Mute Module.
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
#include <voiceannounce_ex>
#include <basecomm>


//Compiler Options
#pragma semicolon 1
#pragma newdecls required


//Console Variables
ConVar gc_bMute;
ConVar gc_bMuteEnd;
ConVar gc_sAdminFlagMute;
ConVar gc_bMuteTalkOver;
ConVar gc_bMuteTalkOverTeam;


//Boolean
bool IsMuted[MAXPLAYERS+1] = {false, ...};
bool TempMuted[MAXPLAYERS+1] = {false, ...};


//Strings
char g_sMuteUser[32];
char g_sAdminFlagMute[32];


//Start
public void Mute_OnPluginStart()
{
	//Client commands
	RegConsoleCmd("sm_wmute", Command_MuteMenu, "Allows a warden to mute all terrorists for a specified duration or untill the next round.");
	RegConsoleCmd("sm_wunmute", Command_UnMuteMenu, "Allows a warden to unmute the terrorists.");
	
	
	//AutoExecConfig
	gc_bMute = AutoExecConfig_CreateConVar("sm_warden_mute", "1", "0 - disabled, 1 - Allow the warden to mute T-side player", _, true, 0.0, true, 1.0);
	gc_bMuteEnd = AutoExecConfig_CreateConVar("sm_warden_mute_round", "1", "0 - disabled, 1 - Allow the warden to mute a player until roundend", _, true, 0.0, true, 1.0);
	gc_sAdminFlagMute = AutoExecConfig_CreateConVar("sm_warden_mute_immuntiy", "a", "Set flag for admin/vip Mute immunity. No flag immunity for all. so don't leave blank!");
	gc_bMuteTalkOver = AutoExecConfig_CreateConVar("sm_warden_talkover", "1", "0 - disabled, 1 - temporary mutes all client when the warden speaks", _, true, 0.0, true, 1.0);
	gc_bMuteTalkOverTeam = AutoExecConfig_CreateConVar("sm_warden_talkover_team", "1", "0 - mute prisoner & guards on talkover, 1 - only mute prisoners on talkover", _, true, 0.0, true, 1.0);
	
	
	//Hooks
	HookConVarChange(gc_sAdminFlagMute, Mute_OnSettingChanged);
	HookEvent("round_end", Mute_Event_RoundEnd);
	
	
	//FindConVar
	gc_sAdminFlagMute.GetString(g_sAdminFlagMute , sizeof(g_sAdminFlagMute));
}


public int Mute_OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == gc_sAdminFlagMute)
	{
		strcopy(g_sAdminFlagMute, sizeof(g_sAdminFlagMute), newValue);
	}
}


/******************************************************************************
                   COMMANDS
******************************************************************************/


public Action Command_UnMuteMenu(int client, any args)
{
	if(gc_bPlugin.BoolValue)	
	{
		if(IsValidClient(client, false, false) && IsClientWarden(client) && gc_bMute.BoolValue)
		{
			char info1[255];
			Menu menu4 = CreateMenu(Handler_UnMuteMenu);
			Format(info1, sizeof(info1), "%T", "warden_choose", client);
			menu4.SetTitle(info1);
			LoopValidClients(i,true,true)
			{
				if((GetClientTeam(i) == CS_TEAM_T) && IsMuted[i])
				{
					char userid[11];
					char username[MAX_NAME_LENGTH];
					IntToString(GetClientUserId(i), userid, sizeof(userid));
					Format(username, sizeof(username), "%N", i);
					menu4.AddItem(userid,username);
				}
			/*	else
				{
					CReplyToCommand(client, "%t %t", "warden_tag", "warden_nomuted");
					FakeClientCommand(client, "sm_wmute");
				}
	*/		}
			menu4.ExitBackButton = true;
			menu4.ExitButton = true;
			menu4.Display(client,MENU_TIME_FOREVER);
		}
		else CReplyToCommand(client, "%t %t", "warden_tag", "warden_notwarden");
	}
	return Plugin_Handled;
}


public Action Command_MuteMenu(int client, int args)
{
	if (gc_bMute.BoolValue) 
	{
		if (IsClientWarden(client))
		{
			char info[255];
			Menu menu1 = CreateMenu(Handler_MuteMenu);
			Format(info, sizeof(info), "%T", "warden_mute_title", g_iWarden, client);
			menu1.SetTitle(info);
			Format(info, sizeof(info), "%T", "warden_menu_mute", client);
			menu1.AddItem("0", info);
			Format(info, sizeof(info), "%T", "warden_menu_unmute", client);
			menu1.AddItem("1", info);
			Format(info, sizeof(info), "%T", "warden_menu_muteall", client);
			menu1.AddItem("2", info);
			Format(info, sizeof(info), "%T", "warden_menu_unmuteall", client);
			menu1.AddItem("3", info);
			menu1.ExitBackButton = true;
			menu1.ExitButton = true;
			menu1.Display(client,MENU_TIME_FOREVER);
		}
		else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_notwarden"); 
	}
	return Plugin_Handled;
}


/******************************************************************************
                   EVENTS
******************************************************************************/


public void Mute_Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	LoopClients(i) if(IsMuted[i]) UnMuteClient(i);
}


/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/


public void Mute_OnAvailableLR(int Announced)
{
	LoopClients(i) if(IsMuted[i] && IsPlayerAlive(i)) UnMuteClient(i);
}


public void Mute_OnMapEnd()
{
	LoopClients(i) if(IsMuted[i]) UnMuteClient(i);
}


// Mute Terror when Warden speaks
public int OnClientSpeakingEx(int client)
{
	if (warden_iswarden(client) && gc_bMuteTalkOver.BoolValue)
	{
		LoopValidClients(i, false, true)
		{
			if (!CheckVipFlag(i,g_sAdminFlagMute))
			{
				if ((GetClientTeam(i) == CS_TEAM_T) && (!IsMuted[i] || (GetClientListeningFlags(i) != VOICE_MUTED)) || 
					(!gc_bMuteTalkOverTeam.BoolValue && !warden_iswarden(i) && (GetClientTeam(i) == CS_TEAM_CT) && (GetClientListeningFlags(i) != VOICE_MUTED)))
				{
					PrintCenterText(i, "%t", "warden_talkover");
					TempMuted[i] = true;
					SetClientListeningFlags(i, VOICE_MUTED);
				}
			}
		}
	}
	else if (TempMuted[client])
	{
		PrintCenterText(client, "%t", "warden_talkover");
	}
}


// Mute Terror when Warden end speaking
public int OnClientSpeakingEnd(int client)
{
	if (warden_iswarden(client) && gc_bMuteTalkOver.BoolValue)
	{
		LoopValidClients(i, false, true)
		{
			if (TempMuted[i] && !IsMuted[i] && !BaseComm_IsClientMuted(i))
			{
				TempMuted[i] = false;
				SetClientListeningFlags(i, VOICE_NORMAL);
			}
		}
	}
}


/******************************************************************************
                   FUNCTIONS
******************************************************************************/


public Action MuteClient(int client, int time)
{
	if(IsValidClient(client,true,true) && !CheckVipFlag(client,g_sAdminFlagMute))
	{
		if(GetClientTeam(client) == CS_TEAM_T)
		{
			SetClientListeningFlags(client, VOICE_MUTED);
			IsMuted[client] = true;
			
			if (time == 0)
			{
				CPrintToChatAll("%t %t", "warden_tag", "warden_muteend", g_iWarden, client);
				if(ActiveLogging()) LogToFileEx(g_sMyJBLogFile, "Warden %L muted player %L until round end", g_iWarden, client);
			}
			else
			{
				CPrintToChatAll("%t %t", "warden_tag", "warden_mute", g_iWarden, client, time);
				if(ActiveLogging()) LogToFileEx(g_sMyJBLogFile, "Warden %L muted player %L for %i seconds", g_iWarden, client, time);
			}
		}
	}
	if(time > 0)
	{
		float timing = float(time);
		CreateTimer(timing, Timer_UnMute,client);
	}
}


public void UnMuteClient(any client)
{
	if(IsValidClient(client,true,true) && IsMuted[client] && !BaseComm_IsClientMuted(client))
	{
		SetClientListeningFlags(client, VOICE_NORMAL);
		IsMuted[client] = false;
		CPrintToChat(client,"%t %t", "warden_tag", "warden_unmute", client);
		if(g_iWarden != -1) CPrintToChat(g_iWarden,"%t %t", "warden_tag", "warden_unmute", client);
	}
}


/******************************************************************************
                   MENUS
******************************************************************************/


public Action MuteMenuPlayer(int client,int args)
{
	if(gc_bPlugin.BoolValue)	
	{
		if(IsValidClient(client, false, false) && IsClientWarden(client) && gc_bMute.BoolValue)
		{
			char info1[255];
			Menu menu5 = CreateMenu(Handler_MuteMenuPlayer);
			Format(info1, sizeof(info1), "%T", "warden_choose", client);
			menu5.SetTitle(info1);
			LoopValidClients(i,true,true)
			{
				if((GetClientTeam(i) == CS_TEAM_T) && !CheckVipFlag(i,g_sAdminFlagMute))
				{
					char userid[11];
					char username[MAX_NAME_LENGTH];
					IntToString(GetClientUserId(i), userid, sizeof(userid));
					Format(username, sizeof(username), "%N", i);
					menu5.AddItem(userid,username);
				}
			}
			menu5.ExitBackButton = true;
			menu5.ExitButton = true;
			menu5.Display(client,MENU_TIME_FOREVER);
		}
		else CReplyToCommand(client, "%t %t", "warden_tag", "warden_notwarden");
	}
	return Plugin_Handled;
}


public int Handler_MuteMenuPlayer(Menu menu5, MenuAction action, int client, int Position)
{
	if(action == MenuAction_Select)
	{
		menu5.GetItem(Position,g_sMuteUser,sizeof(g_sMuteUser));
		
		char menuinfo[255];
		
		Menu menu3 = new Menu(Handler_MuteMenuTime);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_time_title", client);
		menu3.SetTitle(menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_roundend", client);
		if(gc_bMuteEnd.BoolValue) menu3.AddItem("0", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_15", client);
		menu3.AddItem("15", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_30", client);
		menu3.AddItem("30", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_45", client);
		menu3.AddItem("45", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_60", client);
		menu3.AddItem("60", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_90", client);
		menu3.AddItem("90", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_120", client);
		menu3.AddItem("120", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_180", client);
		menu3.AddItem("180", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_300", client);
		menu3.AddItem("300", menuinfo);
		menu3.ExitBackButton = true;
		menu3.ExitButton = true;
		menu3.Display(client, 20);
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
		delete menu5;
	}
}


public int Handler_MuteMenuTime(Menu menu3, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu3.GetItem(selection, info, sizeof(info));
		int duration = StringToInt(info);
		int user = GetClientOfUserId(StringToInt(g_sMuteUser)); 
		
		MuteClient(user,duration);
		
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
		if(selection == MenuCancel_ExitBack) 
		{
			FakeClientCommand(client, "sm_wmute");
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu3;
	}
}


public int Handler_UnMuteMenu(Menu menu4, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu4.GetItem(selection, info, sizeof(info));
		int user = GetClientOfUserId(StringToInt(info)); 
		
		UnMuteClient(user);
		
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
		if(selection == MenuCancel_ExitBack) 
		{
			FakeClientCommand(client, "sm_menu");
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu4;
	}
}


public int Handler_MuteMenu(Menu menu, MenuAction action, int client, int Position)
{
	if(action == MenuAction_Select)
	{
		char Item[11];
		menu.GetItem(Position,Item,sizeof(Item));
		int choice = StringToInt(Item);
		if(choice == 1)
		{
			Command_UnMuteMenu(client,0);
		}
		if(choice == 0)
		{
			MuteMenuPlayer(client,0);
		}
		if(choice == 2)
		{
			MuteMenuTeam(client,0);
		}
		if(choice == 3)
		{
			LoopClients(i) UnMuteClient(i);
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


public int MuteMenuTeam(int client, int args)
{
	char menuinfo[255];
	
	Menu menu6 = new Menu(Handler_MuteMenuTeam);
	Format(menuinfo, sizeof(menuinfo), "%T", "warden_time_title", client);
	menu6.SetTitle(menuinfo);
	Format(menuinfo, sizeof(menuinfo), "%T", "warden_roundend", client);
	if(gc_bMuteEnd.BoolValue) menu6.AddItem("0", menuinfo);
	Format(menuinfo, sizeof(menuinfo), "%T", "warden_15", client);
	menu6.AddItem("15", menuinfo);
	Format(menuinfo, sizeof(menuinfo), "%T", "warden_30", client);
	menu6.AddItem("30", menuinfo);
	Format(menuinfo, sizeof(menuinfo), "%T", "warden_45", client);
	menu6.AddItem("45", menuinfo);
	Format(menuinfo, sizeof(menuinfo), "%T", "warden_60", client);
	menu6.AddItem("60", menuinfo);
	Format(menuinfo, sizeof(menuinfo), "%T", "warden_90", client);
	menu6.AddItem("90", menuinfo);
	Format(menuinfo, sizeof(menuinfo), "%T", "warden_120", client);
	menu6.AddItem("120", menuinfo);
	Format(menuinfo, sizeof(menuinfo), "%T", "warden_180", client);
	menu6.AddItem("180", menuinfo);
	Format(menuinfo, sizeof(menuinfo), "%T", "warden_300", client);
	menu6.AddItem("300", menuinfo);
	menu6.ExitBackButton = true;
	menu6.ExitButton = true;
	menu6.Display(client, 20);
}


public int Handler_MuteMenuTeam(Menu menu6, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu6.GetItem(selection, info, sizeof(info));
		int duration = StringToInt(info);
				
		LoopClients(i) MuteClient(i,duration);
		
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
		if(selection == MenuCancel_ExitBack) 
		{
			FakeClientCommand(client, "sm_wmute");
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu6;
	}
}


/******************************************************************************
                   TIMER
******************************************************************************/


public Action Timer_UnMute(Handle timer, any client)
{
	UnMuteClient(client);
}

