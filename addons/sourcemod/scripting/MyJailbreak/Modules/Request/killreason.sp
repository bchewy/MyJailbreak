/*
 * MyJailbreak - Request Kill Reason Module.
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
ConVar gc_bKillReason;


//Start
public void KillReason_OnPluginStart()
{
	//AutoExecConfig
	gc_bKillReason = AutoExecConfig_CreateConVar("sm_killreason_enable", "1", "0 - disabled, 1 - enable - CT can answer a menu with the kill reason");
	
	
	//Hooks 
	HookEvent("player_death", KillReason_Event_PlayerDeath);
}


/******************************************************************************
                   EVENTS
******************************************************************************/


public void KillReason_Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int victim = GetClientOfUserId(event.GetInt("userid")); // Get the dead clients id
	int attacker = GetClientOfUserId(event.GetInt("attacker")); // Get the attacker clients id
	
	if (IsValidClient(victim, true, true) && IsValidClient(attacker, false, true) && !IsLR && gc_bPlugin.BoolValue && gc_bKillReason.BoolValue && ((GetClientTeam(attacker) == CS_TEAM_CT) && (GetClientTeam(victim) == CS_TEAM_T))) Menu_KillReason(attacker,victim);
}


/******************************************************************************
                   MENUS
******************************************************************************/


public int Menu_KillReason(int client, int victim)
{
	if(!IsEventDayRunning() && !IsLastGuardRule())
	{
		char info[255];
		
		Menu menu1 = CreateMenu(Handler_KillReason);
		Format(info, sizeof(info), "%T", "request_killreason_title", client, victim);
		menu1.SetTitle(info);
		Format(info, sizeof(info), "%T", "request_killreason_lostgame", client, victim);
		if(gc_bFreeKillRespawn.BoolValue) menu1.AddItem("1", info);
		Format(info, sizeof(info), "%T", "request_killreason_rebel", client);
		if(gc_bFreeKillKill.BoolValue) menu1.AddItem("2", info);
		Format(info, sizeof(info), "%T", "request_killreason_brokerule", client);
		if(gc_bFreeKillFreeDay.BoolValue) menu1.AddItem("3", info);
		Format(info, sizeof(info), "%T", "request_killreason_notfollow", client);
		if(gc_bFreeKillFreeDayVictim.BoolValue) menu1.AddItem("4", info);
		Format(info, sizeof(info), "%T", "request_killreason_sry", client);
		if(gc_bFreeKillSwap.BoolValue) menu1.AddItem("5", info);
		Format(info, sizeof(info), "%T", "request_killreason_freekill", client);
		if(gc_bFreeKillSwap.BoolValue) menu1.AddItem("6", info);
		menu1.Display(client, MENU_TIME_FOREVER);
	}
}


public int Handler_KillReason(Menu menu, MenuAction action, int client, int Position)
{
	if(action == MenuAction_Select)
	{
		char Item[11];
		menu.GetItem(Position,Item,sizeof(Item));
		int choice = StringToInt(Item);
		int victim = GetClientOfUserId(g_iHasKilled[client]);
		
		if (IsValidClient(victim, true, true) && IsValidClient(client, false, true))
		{
			if(choice == 1) //lostgame
			{
				CPrintToChatAll("%t %t", "request_tag", "request_killreason_lostgame_chat", client, victim);
			}
			if(choice == 2) //rebel
			{
				CPrintToChatAll("%t %t", "request_tag", "request_killreason_rebel_chat", client, victim);
			}
			if(choice == 3) //broke rule
			{
				CPrintToChatAll("%t %t", "request_tag", "request_killreason_brokerule_chat", client, victim);
			}
			if(choice == 4) //dictate
			{
				CPrintToChatAll("%t %t", "request_tag", "request_killreason_notfollow_chat", client, victim);
			}
			if(choice == 5) //sry
			{
				CPrintToChatAll("%t %t", "request_tag", "request_killreason_sry_chat", client, victim);
				Command_Freekill(victim,0);
			}
			if(choice == 6) //freekill
			{
				CPrintToChatAll("%t %t", "request_tag", "request_killreason_freekill_chat", client, victim);
				Command_Freekill(victim,0);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}