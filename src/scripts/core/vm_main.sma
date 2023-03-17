#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <api_player_model>
#include <vm_main>

#define VM_ROUNDTIME 3.0
#define VM_START_DELAY 10.0

#define VAMPIRE_HOST_HEALTH 3000.0
#define VAMPIRE_NORMAL_HEALTH 2000.0

#define TASK_START 7854
#define TASK_HUD 85698

new bool:g_bGameStarted
new bool:g_bGameShouldCommence

new bool:g_bVampire[MAX_PLAYERS+1]
new g_iVampiresCount

new g_iHudSync

public plugin_precache() {
	precache_model(MODEL_VAMPIRE_HOST)
	precache_model(MODEL_VAMPIRE_NORMAL)
	precache_model(MODEL_VAMPIRE_HANDS_HOST)
	precache_model(MODEL_VAMPIRE_HANDS_NORMAL)
}

public plugin_init() {
	register_plugin("[VM] main", VM_VERSION, "JustGo")

	RegisterHookChain(RG_CSGameRules_FPlayerCanRespawn, "RHook_FPlayerCanRespawn");
	RegisterHookChain(RG_CSGameRules_RestartRound, "RHook_RestartRound")
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "RHook_OnRoundFreezeEnd_Post", 1)
	RegisterHookChain(RG_RoundEnd, "RHook_RoundEnd_Post", 1)
	RegisterHookChain(RG_CSGameRules_FPlayerCanTakeDamage, "RHook_FPlayerCanTakeDamage");
	RegisterHookChain(RG_CSGameRules_CheckWinConditions, "RHook_CheckWinConditions");
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "RHook_HandleMenu_ChooseTeam");

	RegisterHamPlayer(Ham_Killed, "HHook_Player_Killed_Post", 1)

	register_clcmd("chooseteam", "CHook_ChooseTeam");
	register_clcmd("jointeam", "CHook_JoinTeam");
	register_clcmd("joinclass", "CHook_JoinClass");

	g_iHudSync = CreateHudSyncObj()
}

public plugin_cfg() {
	set_cvar_float("mp_roundtime", VM_ROUNDTIME)
	set_cvar_num("mp_freezetime", 3)
	set_cvar_num("mp_roundover", 1)
	set_cvar_num("mp_buytime", 0)
	set_cvar_num("mp_give_player_c4", 0);
	set_cvar_num("mp_autoteambalance", 0)
	set_cvar_num("mp_limitteams", 0)
	set_cvar_num("mp_auto_join_team", 1)
	set_cvar_string("humans_join_team", "SPEC")
	set_cvar_num("sv_allchat", 1)
	set_cvar_num("sv_restart", 1)
}

public plugin_natives() {
	register_native("VM_GameStarted", "Native_GameStarted")
	register_native("VM_SetVampire", "Native_SetVampire")
}

public Native_GameStarted(plugin_id, argc) {
	return g_bGameStarted;
}

public Native_SetVampire(plugin_id, argc) {
	new pPlayer = get_param(1)
	SetVampire(pPlayer)
	return true
}


public CHook_ChooseTeam(pPlayer) {
	ShowGameMenu(pPlayer)
	return PLUGIN_HANDLED_MAIN
}

public CHook_JoinTeam(pPlayer) {
	return PLUGIN_HANDLED_MAIN
}

public CHook_JoinClass(pPlayer) {
	return PLUGIN_HANDLED_MAIN
}

public RHook_FPlayerCanRespawn(const pPlayer) {

	if(g_bGameStarted)
	{
		SetHookChainReturn(ATYPE_INTEGER, false);
		return HC_SUPERCEDE;
	}

	// TODO: verify if we need this
	if(get_member(pPlayer, m_iMenu) == Menu_ChooseAppearance)
	{
		SetHookChainReturn(ATYPE_INTEGER, false);
		return HC_SUPERCEDE;
	}

	SetHookChainReturn(ATYPE_INTEGER, true);
	return HC_SUPERCEDE;
}

public RHook_RestartRound() {
	remove_task(TASK_START)
	remove_task(TASK_HUD)
	g_iVampiresCount = 0
	g_bGameStarted = false

	for (new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
		if (!is_user_connected(pPlayer)) continue

		if (get_member(pPlayer, m_iTeam) == TEAM_CT) continue

		g_bVampire[pPlayer] = false
		set_member(pPlayer, m_iTeam, TEAM_CT)

		PlayerModel_Reset(pPlayer)
	}
}

public RHook_OnRoundFreezeEnd_Post() {
	set_task(VM_START_DELAY, "VM_ChooseHost", TASK_START)

	set_dhudmessage(255, 0, 0, _, _, _, _, 5.0)
	show_dhudmessage(0, "Be aware! Vampires will appear in 10 seconds")
}

public VM_ChooseHost() {
	g_bGameStarted = true

	new Array:aAlivePlayers
	aAlivePlayers = ArrayCreate()

	new iAliveCount

	for (new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
		if (!is_user_alive(pPlayer)) continue

		ArrayPushCell(aAlivePlayers, pPlayer)
		iAliveCount++
	}

	if (iAliveCount < 2) {
		g_bGameShouldCommence = true
		return
	}

	new iTarget = random(iAliveCount)
	SetVampire(ArrayGetCell(aAlivePlayers, iTarget), true)

	set_task(1.0, "Task_Hud", TASK_HUD, _, _, "b")
}

public Task_Hud() {
	/*
	for (new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
		if (!is_user_connected(pPlayer)) continue


	}
	*/
	set_hudmessage(255, 255, 255, _, 0.02, _, _, 1.5)
	ShowSyncHudMsg(0, g_iHudSync, "Vampire - Hunter^n%d    VS    %d", g_iVampiresCount, GetHuntersCount())
}

public RHook_RoundEnd_Post(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) {
	remove_task(TASK_START)
	g_bGameStarted = false
	g_iVampiresCount = 0
}

public RHook_FPlayerCanTakeDamage(const pPlayer, const pAttacker) {
	if(g_bGameStarted)
		return HC_CONTINUE;

	SetHookChainReturn(ATYPE_INTEGER, false);
	return HC_SUPERCEDE;
}

public RHook_CheckWinConditions() {
	if (get_member_game(m_iRoundWinStatus))
		return HC_CONTINUE;

	if (g_bGameShouldCommence) {
		rg_round_end(3.0, WINSTATUS_DRAW, ROUND_GAME_COMMENCE, "")
	} else if (g_iVampiresCount <= 0) {
		rg_round_end(5.0, WINSTATUS_CTS, ROUND_CTS_WIN, "Hunters Win")
	} else if (GetHuntersCount() <= 0) {
		rg_round_end(5.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "Vampires Win")
	}

	return HC_SUPERCEDE;
}

public RHook_HandleMenu_ChooseTeam(const pPlayer, const MenuChooseTeam:slot)
{
	// Disable class menu from appearing
	set_member_game(m_bSkipShowMenu, true)
	ShowGameMenu(pPlayer)
}

public ShowGameMenu(pPlayer) {
	new iMenu = menu_create("", "Handler_GameMenu")

	menu_additem(iMenu, "Join Game")
	menu_additem(iMenu, "Join Spec")

	menu_display(pPlayer, iMenu)
}

public Handler_GameMenu(pPlayer, iMenu, iItem) {
	if (iItem == MENU_EXIT) goto MENU_END

	switch (iItem) {
		case 0: {
			rg_join_team(pPlayer, TEAM_CT)
		}
		case 1: {
			rg_join_team(pPlayer, TEAM_SPECTATOR)
		}
	}

	MENU_END: 
	menu_destroy(iMenu)
}

public HHook_Player_Killed_Post(pVictim) {
	if (get_member(pVictim, m_iTeam) != TEAM_TERRORIST) return HAM_IGNORED

	if (get_member(pVictim, m_bDontRespawn)) {
		g_iVampiresCount--
		rg_check_win_conditions()
	}

	return HAM_IGNORED
}

SetVampire(pPlayer, bool:bIsHost = false) {
	rg_set_user_team(pPlayer, TEAM_TERRORIST, MODEL_UNASSIGNED)
	rg_remove_items_by_slot(pPlayer, GRENADE_SLOT)
	rg_drop_items_by_slot(pPlayer, PRIMARY_WEAPON_SLOT)
	rg_drop_items_by_slot(pPlayer, PISTOL_SLOT)

	if (bIsHost) {
		PlayerModel_Set(pPlayer, MODEL_VAMPIRE_HOST)
		set_pev(pPlayer, pev_viewmodel2, MODEL_VAMPIRE_HANDS_HOST);
		set_pev(pPlayer, pev_health, VAMPIRE_HOST_HEALTH)
		set_pev(pPlayer, pev_max_health, VAMPIRE_HOST_HEALTH)
	} else {
		PlayerModel_Set(pPlayer, MODEL_VAMPIRE_NORMAL)
		set_pev(pPlayer, pev_viewmodel2, MODEL_VAMPIRE_HANDS_NORMAL);
		set_pev(pPlayer, pev_health, VAMPIRE_NORMAL_HEALTH)
		set_pev(pPlayer, pev_max_health, VAMPIRE_NORMAL_HEALTH)
	}
	PlayerModel_Update(pPlayer);

	set_pev(pPlayer, pev_weaponmodel2, "");

	if (!g_bVampire[pPlayer]) {
		g_iVampiresCount++
		g_bVampire[pPlayer] = true
	}
	
}

public client_disconnected(pPlayer) {
	if (g_bVampire[pPlayer]) {
		g_iVampiresCount--
	}
}

GetHuntersCount() {
	new iCount
	for (new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
		if (!is_user_alive(pPlayer)) continue

		if (get_member(pPlayer, m_iTeam) != TEAM_CT) continue

		iCount++
	}
	return iCount
}