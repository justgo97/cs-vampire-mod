#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <fakemeta>
#include <fun>
#include <api_player_model>
#include <screenfade_util>

#include <vm_main>

#define BOOST_COOLDOWN 15.0
#define BOOST_TIME 5.0
#define RESPAWN_TIME 3.0

new Float:g_fLastBoost[MAX_PLAYERS+1];

new g_iRageLevel
new bool:g_bLycan[MAX_PLAYERS+1];

new bool:g_bNewOrigin[MAX_PLAYERS+1]

new g_iHudSync

#define TASK_RESPAWN 7648
#define TASK_END_BOOST 98988

public plugin_precache() {
	precache_model(MODEL_LYCAN)
	precache_model(MODEL_LYCAN_HANDS)
}

public plugin_init() {
	register_plugin("[VM] Abilities", VM_VERSION, "JustGo")

	RegisterHookChain(RG_CSGameRules_RestartRound, "RHook_RestartRound")
	RegisterHamPlayer(Ham_ObjectCaps, "HHook_Player_ObjectCaps")
	RegisterHamPlayer(Ham_Killed, "HHook_Player_Killed_Post", 1)

	g_iHudSync = CreateHudSyncObj()
}

public plugin_natives() {
	register_native("VM_GetRage", "Native_GetRage")
}

public Native_GetRage(plugin_id, argc) {
	return g_iRageLevel;
}

public RHook_RestartRound() {
	g_iRageLevel = 1
	arrayset(g_bNewOrigin, false, sizeof(g_bNewOrigin) )
	arrayset(g_bLycan, false, sizeof(g_bLycan) )
}

public HHook_Player_ObjectCaps(pPlayer) {
	if (!VM_GameStarted()) return HAM_IGNORED

	if (!is_user_alive(pPlayer))
		return HAM_IGNORED;

	if (get_member(pPlayer, m_afButtonPressed) & IN_USE) {
		OnPlayerUse(pPlayer)
	}

	return HAM_IGNORED;
}

public OnPlayerUse(pPlayer) {
	new TeamName:iTeam = get_member(pPlayer, m_iTeam)
	if (g_iRageLevel >= 10 && iTeam == TEAM_CT) {
		MakeLycan(pPlayer)
		return
	}

	new Float:fGameTime = get_gametime()

	if (g_fLastBoost[pPlayer] < fGameTime) {
		switch (iTeam) {
			case TEAM_CT: {
				HunterBoost(pPlayer)
			}
			case TEAM_TERRORIST: {
				VampireBoost(pPlayer)
			}
		}
		g_fLastBoost[pPlayer] = fGameTime + BOOST_COOLDOWN
	}
}

public HunterBoost(pPlayer) {
	set_pev(pPlayer, pev_maxspeed, 320.0)
	set_user_rendering(pPlayer, kRenderFxGlowShell, 0, 0, 200)
	UTIL_ScreenFade(pPlayer, {0, 0 ,200}, BOOST_TIME, BOOST_TIME, 10)
	set_task(BOOST_TIME, "Task_HunterBoost", TASK_END_BOOST + pPlayer)
}

public Task_HunterBoost(iTaskID) {
	new pPlayer = iTaskID - TASK_END_BOOST

	set_user_rendering(pPlayer)
	set_pev(pPlayer, pev_maxspeed, 250.0)
}

public VampireBoost(pPlayer) {
	set_pev(pPlayer, pev_maxspeed, 350.0)
	set_user_rendering(pPlayer, kRenderFxGlowShell, 200)
	UTIL_ScreenFade(pPlayer, {200, 0 ,0}, BOOST_TIME, BOOST_TIME, 10)
	set_task(BOOST_TIME, "Task_VampireBoost", TASK_END_BOOST + pPlayer)
}

public Task_VampireBoost(iTaskID) {
	new pPlayer = iTaskID - TASK_END_BOOST

	set_user_rendering(pPlayer)
	set_pev(pPlayer, pev_maxspeed, 300.0)
}

public MakeLycan(pPlayer) {
	if (g_bLycan[pPlayer]) return

	PlayerModel_Set(pPlayer, MODEL_LYCAN)
	PlayerModel_Update(pPlayer);
	set_pev(pPlayer, pev_viewmodel2, MODEL_LYCAN_HANDS);
	set_pev(pPlayer, pev_weaponmodel2, "");
}

public HHook_Player_Killed_Post(pVictim, pKiller) {
	if (!VM_GameStarted()) return

	if (g_bLycan[pVictim]) return

	if (get_member(pVictim, m_iTeam) == TEAM_TERRORIST) {
		g_bNewOrigin[pVictim] = true
	}

	if (get_member(pVictim, m_iTeam) == TEAM_CT) {
		if (g_iRageLevel < 10) {
			g_iRageLevel++
			for (new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
				if (!is_user_alive(pPlayer)) continue

				if (get_member(pPlayer, m_iTeam) != TEAM_CT) continue

				set_hudmessage(0, 0, 100, _, _, _, _, 5.0)
				ShowSyncHudMsg(pPlayer, g_iHudSync, "Human Rage Increase - Increase Attack Power %d0%", g_iRageLevel)
			}
		}

	}

	if (!get_member_game(m_iRoundWinStatus)) {
		if (!get_member(pVictim, m_bDontRespawn)) {
			if (!g_bNewOrigin[pVictim]) {
				static Float:fOrigin[3]
				get_entvar(pVictim, var_origin, fOrigin)
				set_entvar(pVictim, var_vuser2, fOrigin)
			}
			
			VM_Respawn(pVictim)
		}
	}
}

public VM_Respawn(pPlayer) {
	rg_send_bartime(pPlayer, floatround(RESPAWN_TIME), false)
	set_task(RESPAWN_TIME, "Task_Respawn", TASK_RESPAWN+pPlayer)
}

public Task_Respawn(iTaskID) {
	new pPlayer = iTaskID - TASK_RESPAWN

	if (get_member_game(m_iRoundWinStatus)) return

	if (!is_user_connected(pPlayer)) return

	if (is_user_alive(pPlayer)) return

	ExecuteHamB(Ham_CS_RoundRespawn, pPlayer);
	VM_SetVampire(pPlayer)
	if (!g_bNewOrigin[pPlayer]) {
		new Float:fOrigin[3]
		get_entvar(pPlayer, var_vuser2, fOrigin)
		engfunc(EngFunc_SetOrigin, pPlayer, fOrigin)
		g_bNewOrigin[pPlayer] = true
	}
}