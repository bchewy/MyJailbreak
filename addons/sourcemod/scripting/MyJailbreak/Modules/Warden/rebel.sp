/*
 * MyJailbreak - Warden - Mark Rebel Module.
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
ConVar gc_bMarkRebel;



//Extern Convars
ConVar g_bHostiesColor;
ConVar g_iHostiesR;
ConVar g_iHostiesG;
ConVar g_iHostiesB;
ConVar g_bHostiesAnnounce;
ConVar g_bHostiesAnnounceGlobal;


//Start
public void MarkRebel_OnPluginStart()
{
	//Translation
	LoadTranslations("hosties.phrases");
	
	
	//Client commands
	RegConsoleCmd("sm_markrebel", Command_MarkRebel, "Allows Warden to mark/unmark prisoner as rebel");
	
	
	//AutoExecConfig
	gc_bMarkRebel = AutoExecConfig_CreateConVar("sm_warden_mark_rebel", "1", "0 - disabled, 1 - enable allow warden to mark/unmark prisoner as rebel (hosties)", _, true,  0.0, true, 1.0);
	
	
	//FindConVar
	g_bHostiesColor = FindConVar("sm_hosties_rebel_color");
	g_iHostiesG = FindConVar("sm_hosties_rebel_green");
	g_iHostiesR = FindConVar("sm_hosties_rebel_red");
	g_iHostiesB = FindConVar("sm_hosties_rebel_blue");
	g_bHostiesAnnounce = FindConVar("sm_hosties_announce_rebel");
	g_bHostiesAnnounceGlobal = FindConVar("sm_hosties_lr_send_global_msgs");
}


/******************************************************************************
                   COMMANDS
******************************************************************************/


public Action Command_MarkRebel(int client, int args)
{
	if(gc_bPlugin.BoolValue)
	{
		if(gc_bMarkRebel.BoolValue)
		{
			if (IsClientWarden(client))
			{
				Menu_MarkRebelMenu(client);
			}
			else CReplyToCommand(client, "%t %t", "warden_tag" , "warden_notwarden"); 
		}
	}
	return Plugin_Handled;
}


/******************************************************************************
                   MENUS
******************************************************************************/


public Action Menu_MarkRebelMenu(int client)
{
	char menuinfo[255];
	
	Format(menuinfo, sizeof(menuinfo), "%T", "warden_rebel_title", client);
	
	Menu MarkMenu = new Menu(Handler_MarkRebelMenu);
	MarkMenu.SetTitle(menuinfo);
	
	Format(menuinfo, sizeof(menuinfo), "%T", "warden_rebel_mark", client);
	MarkMenu.AddItem("rebel", menuinfo);
	
	Format(menuinfo, sizeof(menuinfo), "%T", "warden_rebel_unmark", client);
	MarkMenu.AddItem("unrebel", menuinfo);
	
	MarkMenu.ExitButton = true;
	MarkMenu.Display(client, MENU_TIME_FOREVER);
}


public int Handler_MarkRebelMenu(Menu MarkMenu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		MarkMenu.GetItem(selection, info, sizeof(info));
		
		if ( strcmp(info,"rebel") == 0 ) 
		{
			char info1[255];
			Menu MarkRebel = CreateMenu(Handler_MarkRebel);
			Format(info1, sizeof(info1), "%T", "warden_choose", client);
			MarkRebel.SetTitle(info1);
			LoopValidClients(i,true,true)
			{
				if(!IsClientRebel(i)&& (GetClientTeam(i) == CS_TEAM_T))
				{
					char userid[11];
					char username[MAX_NAME_LENGTH];
					IntToString(GetClientUserId(i), userid, sizeof(userid));
					Format(username, sizeof(username), "%N", i);
					MarkRebel.AddItem(userid,username);
				}
			}
			MarkRebel.ExitBackButton = true;
			MarkRebel.ExitButton = true;
			MarkRebel.Display(client,MENU_TIME_FOREVER);
		}
		if ( strcmp(info,"unrebel") == 0 ) 
		{
			char info1[255];
			Menu UnMarkMenu = CreateMenu(Handler_UnMarkRebel);
			Format(info1, sizeof(info1), "%T", "warden_choose", client);
			UnMarkMenu.SetTitle(info1);
			LoopValidClients(i,true,true)
			{
				if(IsClientRebel(i))
				{
					char userid[11];
					char username[MAX_NAME_LENGTH];
					IntToString(GetClientUserId(i), userid, sizeof(userid));
					Format(username, sizeof(username), "%N", i);
					UnMarkMenu.AddItem(userid,username);
				}
			}
			UnMarkMenu.ExitBackButton = true;
			UnMarkMenu.ExitButton = true;
			UnMarkMenu.Display(client,MENU_TIME_FOREVER);
		}
	}
	else if(action == MenuAction_Cancel) 
	{
		if(selection == MenuCancel_ExitBack) 
		{
			Menu_MarkRebelMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		delete MarkMenu;
	}
}


public int Handler_MarkRebel(Menu MarkRebel, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		MarkRebel.GetItem(selection, info, sizeof(info));
		int i = GetClientOfUserId(StringToInt(info));
		ChangeRebelStatus(i, true);
		
		if (g_bHostiesAnnounce.BoolValue && IsClientInGame(i))  //hosties cvars
		{
			if (g_bHostiesAnnounceGlobal.BoolValue) //hosties cvars
			{
				CPrintToChatAll("%t %t", "warden_tag", "New Rebel", i);  //hosties phrases
			}
			else
			{
				CPrintToChat(i, "%t %t", "warden_tag", "New Rebel", i);  //hosties phrases
				CPrintToChat(client, "%t %t", "warden_tag", "New Rebel", i);  //hosties phrases
			}
		}
		if (g_bHostiesColor.BoolValue) //hosties cvars
		{
			SetEntityRenderColor(i, g_iHostiesR.IntValue, g_iHostiesG.IntValue, g_iHostiesB.IntValue, 255); //hosties cvars
		}
		
		Menu_MarkRebelMenu(client);
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
		delete MarkRebel;
	}
}


public int Handler_UnMarkRebel(Menu UnMarkRebel, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		UnMarkRebel.GetItem(selection, info, sizeof(info));
		int i = GetClientOfUserId(StringToInt(info));
		ChangeRebelStatus(i, false);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		Menu_MarkRebelMenu(client);
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
		delete UnMarkRebel;
	}
}