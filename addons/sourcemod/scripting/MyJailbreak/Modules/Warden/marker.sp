/*
 * MyJailbreak - Warden - Marker Module.
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
ConVar gc_bMarker;


//Booleans
bool g_bMarkerSetup;
bool g_bCanZoom[MAXPLAYERS + 1];
bool g_bHasSilencer[MAXPLAYERS + 1];


//Integers
int g_iWrongWeapon[MAXPLAYERS+1];


//Strings
char g_sColorNamesRed[64];
char g_sColorNamesBlue[64];
char g_sColorNamesGreen[64];
char g_sColorNamesOrange[64];
char g_sColorNamesMagenta[64];
char g_sColorNamesRainbow[64];
char g_sColorNamesYellow[64];
char g_sColorNamesCyan[64];
char g_sColorNamesWhite[64];
char g_sColorNames[8][64] ={{""},{""},{""},{""},{""},{""},{""},{""}};


//float
float g_fMarkerRadiusMin = 100.0;
float g_fMarkerRadiusMax = 500.0;
float g_fMarkerRangeMax = 1500.0;
float g_fMarkerArrowHeight = 90.0;
float g_fMarkerArrowLength = 20.0;
float g_fMarkerSetupStartOrigin[3];
float g_fMarkerSetupEndOrigin[3];
float g_fMarkerOrigin[8][3];
float g_fMarkerRadius[8];


//Start
public void Marker_OnPluginStart()
{
	//AutoExecConfig
	gc_bMarker = AutoExecConfig_CreateConVar("sm_warden_marker", "1", "0 - disabled, 1 - enable Warden advanced markers ", _, true,  0.0, true, 1.0);
	
	//Hooks
	HookEvent("item_equip", Marker_Event_ItemEquip);
	
	CreateTimer(1.0, Timer_DrawMakers, _, TIMER_REPEAT);
	
	PrepareMarkerNames();
}

public void PrepareMarkerNames()
{
	//Prepare translation for marker colors
	Format(g_sColorNamesRed, sizeof(g_sColorNamesRed), "{darkred}%T{default}", "warden_red", LANG_SERVER);
	Format(g_sColorNamesBlue, sizeof(g_sColorNamesBlue), "{blue}%T{default}", "warden_blue", LANG_SERVER);
	Format(g_sColorNamesGreen, sizeof(g_sColorNamesGreen), "{green}%T{default}", "warden_green", LANG_SERVER);
	Format(g_sColorNamesOrange, sizeof(g_sColorNamesOrange), "{lightred}%T{default}", "warden_orange", LANG_SERVER);
	Format(g_sColorNamesMagenta, sizeof(g_sColorNamesMagenta), "{purple}%T{default}", "warden_magenta", LANG_SERVER);
	Format(g_sColorNamesYellow, sizeof(g_sColorNamesYellow), "{orange}%T{default}", "warden_yellow", LANG_SERVER);
	Format(g_sColorNamesWhite, sizeof(g_sColorNamesWhite), "{default}%T{default}", "warden_white", LANG_SERVER);
	Format(g_sColorNamesCyan, sizeof(g_sColorNamesCyan), "{blue}%T{default}", "warden_cyan", LANG_SERVER);
	Format(g_sColorNamesRainbow, sizeof(g_sColorNamesRainbow), "{lightgreen}%T{default}", "warden_rainbow", LANG_SERVER);
	
	g_sColorNames[0] = g_sColorNamesWhite;
	g_sColorNames[1] = g_sColorNamesRed;
	g_sColorNames[3] = g_sColorNamesBlue;
	g_sColorNames[2] = g_sColorNamesGreen;
	g_sColorNames[7] = g_sColorNamesOrange;
	g_sColorNames[6] = g_sColorNamesMagenta;
	g_sColorNames[4] = g_sColorNamesYellow;
	g_sColorNames[5] = g_sColorNamesCyan;
}


/******************************************************************************
                   EVENTS
******************************************************************************/


public void Marker_Event_ItemEquip(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	g_bCanZoom[client] = event.GetBool("canzoom");
	g_bHasSilencer[client] = event.GetBool("hassilencer");
	g_iWrongWeapon[client] = event.GetInt("weptype");
}


/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/


public Action Marker_OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & IN_ATTACK2)
	{
		if (gc_bMarker.BoolValue && !g_bCanZoom[client] && !g_bHasSilencer[client] && (g_iWrongWeapon[client] != 0) && (g_iWrongWeapon[client] != 8) && (!StrEqual(g_sEquipWeapon[client], "taser")))
		{
			if(!g_bMarkerSetup)
				GetClientAimTargetPos(client, g_fMarkerSetupStartOrigin);
			
			GetClientAimTargetPos(client, g_fMarkerSetupEndOrigin);
			
			float radius = 2*GetVectorDistance(g_fMarkerSetupEndOrigin, g_fMarkerSetupStartOrigin);
			
			if (radius > g_fMarkerRadiusMax)
				radius = g_fMarkerRadiusMax;
			else if (radius < g_fMarkerRadiusMin)
				radius = g_fMarkerRadiusMin;
			
			if (radius > 0)
			{
				TE_SetupBeamRingPoint(g_fMarkerSetupStartOrigin, radius, radius+0.1, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.1, 2.0, 0.0, {255,255,255,255}, 10, 0);
				TE_SendToClient(client);
			}
			
			g_bMarkerSetup = true;
		}
	}
	else if (g_bMarkerSetup)
	{
		MarkerMenu(client);
		g_bMarkerSetup = false;
	}
}


public void Marker_OnWardenRemoved()
{
	RemoveAllMarkers();
}


public void Marker_OnMapEnd()
{
	RemoveAllMarkers();
}


public void Marker_OnMapStart()
{
	RemoveAllMarkers();
}


/******************************************************************************
                   MENUS
******************************************************************************/


stock void MarkerMenu(int client)
{
	if(!(0 < client < MaxClients) || !IsClientWarden(client))
	{
		CPrintToChat(client, "%t %t", "warden_tag", "warden_notwarden");
		return;
	}
	
	int marker = IsMarkerInRange(g_fMarkerSetupStartOrigin);
	if (marker != -1)
	{
		RemoveMarker(marker);
		CPrintToChatAll("%t %t", "warden_tag", "warden_marker_remove", g_sColorNames[marker]);
		return;
	}
	
	float radius = 2*GetVectorDistance(g_fMarkerSetupEndOrigin, g_fMarkerSetupStartOrigin);
	if (radius <= 0.0)
	{
		RemoveMarker(marker);
		CPrintToChat(client, "%t %t", "warden_tag", "warden_wrong");
		return;
	}
	
	float g_fPos[3];
	Entity_GetAbsOrigin(g_iWarden, g_fPos);
	
	float range = GetVectorDistance(g_fPos, g_fMarkerSetupStartOrigin);
	if (range > g_fMarkerRangeMax)
	{
		CPrintToChat(client, "%t %t", "warden_tag", "warden_range");
		return;
	}
	
	if (0 < client < MaxClients)
	{
		Handle menu = CreateMenu(Handle_MarkerMenu);
		
		char menuinfo[255];
		
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_marker_title", client);
		SetMenuTitle(menu, menuinfo);
		
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_red", client);
		AddMenuItem(menu, "1", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_blue", client);
		AddMenuItem(menu, "3", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_green", client);
		AddMenuItem(menu, "2", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_orange", client);
		AddMenuItem(menu, "7", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_white", client);
		AddMenuItem(menu, "0", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_cyan", client);
		AddMenuItem(menu, "5", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_magenta", client);
		AddMenuItem(menu, "6", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "%T", "warden_yellow", client);
		AddMenuItem(menu, "4", menuinfo);
		
		DisplayMenu(menu, client, 20);
	}
}


public int Handle_MarkerMenu(Handle menu, MenuAction action, int client, int itemNum)
{
	if(!(0 < client < MaxClients))
		return;
	
	if(!IsValidClient(client, false, false))
		return;
	
	if (client != g_iWarden)
	{
		CPrintToChat(client, "%t %t", "warden_tag", "warden_notwarden");
		return;
	}
	
	if (action == MenuAction_Select)
	{
		char info[32]; char info2[32];
		bool found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		int marker = StringToInt(info);
		
		if (found)
		{
			SetupMarker(client, marker);
			CPrintToChatAll("%t %t", "warden_tag", "warden_marker_set", g_sColorNames[marker]);
		}
	}
}


/******************************************************************************
                   TIMER
******************************************************************************/


public Action Timer_DrawMakers(Handle timer, any data)
{
	Draw_Markers();
	return Plugin_Continue;
}


/******************************************************************************
                   STOCKS
******************************************************************************/


stock void Draw_Markers()
{
	if (g_iWarden == -1)
		return;
	
	for(int i = 0; i<8; i++)
	{
		if (g_fMarkerRadius[i] <= 0.0)
			continue;
		
		float fWardenOrigin[3];
		Entity_GetAbsOrigin(g_iWarden, fWardenOrigin);
		
		if (GetVectorDistance(fWardenOrigin, g_fMarkerOrigin[i]) > g_fMarkerRangeMax)
		{
			CPrintToChat(g_iWarden, "%t %t", "warden_tag", "warden_marker_faraway", g_sColorNames[i]);
			RemoveMarker(i);
			continue;
		}
		
		LoopValidClients(iClient, false, false)
		{
			
			// Show the ring
			
			TE_SetupBeamRingPoint(g_fMarkerOrigin[i], g_fMarkerRadius[i], g_fMarkerRadius[i]+0.1, g_iBeamSprite, g_iHaloSprite, 0, 10, 1.0, 2.0, 0.0, g_iColors[i], 10, 0);
			TE_SendToAll();
			
			// Show the arrow
			
			float fStart[3];
			AddVectors(fStart, g_fMarkerOrigin[i], fStart);
			fStart[2] += g_fMarkerArrowHeight;
			
			float fEnd[3];
			AddVectors(fEnd, fStart, fEnd);
			fEnd[2] += g_fMarkerArrowLength;
			
			TE_SetupBeamPoints(fStart, fEnd, g_iBeamSprite, g_iHaloSprite, 0, 10, 1.0, 2.0, 16.0, 1, 0.0, g_iColors[i], 5);
			TE_SendToAll();
		}
	}
}


stock void SetupMarker(int client, int marker)
{
	g_fMarkerOrigin[marker][0] = g_fMarkerSetupStartOrigin[0];
	g_fMarkerOrigin[marker][1] = g_fMarkerSetupStartOrigin[1];
	g_fMarkerOrigin[marker][2] = g_fMarkerSetupStartOrigin[2];
	
	float radius = 2*GetVectorDistance(g_fMarkerSetupEndOrigin, g_fMarkerSetupStartOrigin);
	if (radius > g_fMarkerRadiusMax)
		radius = g_fMarkerRadiusMax;
	else if (radius < g_fMarkerRadiusMin)
		radius = g_fMarkerRadiusMin;
	g_fMarkerRadius[marker] = radius;
}


stock int GetClientAimTargetPos(int client, float g_fPos[3]) 
{
	if (client < 1) 
		return -1;
	
	float vAngles[3]; float vOrigin[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilterAllEntities, client);
	
	TR_GetEndPosition(g_fPos, trace);
	g_fPos[2] += 5.0;
	
	int entity = TR_GetEntityIndex(trace);
	
	CloseHandle(trace);
	
	return entity;
}


stock void RemoveMarker(int marker)
{
	if(marker != -1)
	{
		g_fMarkerRadius[marker] = 0.0;
	}
}


stock void RemoveAllMarkers()
{
	for(int i = 0; i < 8;i++)
		RemoveMarker(i);
}


stock int IsMarkerInRange(float g_fPos[3])
{
	for(int i = 0; i < 8;i++)
	{
		if (g_fMarkerRadius[i] <= 0.0)
			continue;
		
		if (GetVectorDistance(g_fMarkerOrigin[i], g_fPos) < g_fMarkerRadius[i])
			return i;
	}
	return -1;
}


public bool TraceFilterAllEntities(int entity, int contentsMask, any client)
{
	if (entity == client)
		return false;
	if (entity > MaxClients)
		return false;
	if(!IsClientInGame(entity))
		return false;
	if(!IsPlayerAlive(entity))
		return false;
	
	return true;
}