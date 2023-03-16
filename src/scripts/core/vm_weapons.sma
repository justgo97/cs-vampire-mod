#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <fakemeta>
#include <vm_main>

#define KNIFE_STABHIT 4

#define KNIFE_STAB_DAMAGE 1500.0
#define AWP_HEADSHOT_DAMAGE 5000.0

public plugin_precache() {
	precache_model(MODEL_HUNTER_KNIFE)
}

public plugin_init() {
	register_plugin("[VM] Weapons", VM_VERSION, "JustGo")

	RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "RHook_Player_OnSpawnEquip")
	RegisterHamPlayer(Ham_TraceAttack, "HHook_Player_TraceAttack")
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "HHook_Knife_Deploy_Post", 1);
}

public RHook_Player_OnSpawnEquip(const pPlayer, bool:addDefault, bool:equipGame) {
	rg_remove_all_items(pPlayer)
	rg_give_item(pPlayer, "weapon_knife")
	set_member(pPlayer, m_bDontRespawn, false)

	if (get_member(pPlayer, m_iTeam) == TEAM_CT) {
		rg_give_item(pPlayer, "weapon_glock18")
		rg_set_user_bpammo( pPlayer, rg_get_weapon_info("weapon_glock18", WI_ID), 80)

		rg_give_item(pPlayer, "weapon_famas")
		rg_set_user_bpammo( pPlayer, rg_get_weapon_info("weapon_famas", WI_ID), 90)
	}

	ShowWeaponsMenu(pPlayer)
	return HC_SUPERCEDE
}

public HHook_Player_TraceAttack(pVictim, pAttacker, Float:fDamage, Float:fDirection[3], tracehandle) {
	if (!is_user_connected(pVictim)) return HAM_IGNORED

	if (get_member(pVictim, m_iTeam) != TEAM_TERRORIST) return HAM_IGNORED

	if (!is_user_alive(pAttacker)) return HAM_IGNORED

	if (get_member(pAttacker, m_iTeam) != TEAM_CT) return HAM_IGNORED

	new Float:fHealth
	pev(pVictim, pev_health, fHealth);
	
	if (get_user_weapon(pAttacker) == CSW_KNIFE) {
		if (fHealth <= fDamage) {
			set_member(pVictim, m_bDontRespawn, true)
		}

		if (pev(pAttacker, pev_weaponanim) == KNIFE_STABHIT) {
			if (fHealth <= KNIFE_STAB_DAMAGE) {
				set_member(pVictim, m_bDontRespawn, true)
			}

			SetHamParamFloat(3, KNIFE_STAB_DAMAGE)
			return HAM_OVERRIDE
		}
	}

	if (get_tr2(tracehandle, TR_iHitgroup) == HIT_HEAD && get_user_weapon(pAttacker) == CSW_AWP) {
		SetHamParamFloat(3, AWP_HEADSHOT_DAMAGE)
		return HAM_OVERRIDE
	}

	SetHamParamFloat(3, float(VM_GetRage()) * fDamage)
	return HAM_OVERRIDE
}

public HHook_Knife_Deploy_Post(knife) {
	if(pev_valid(knife) != 2)
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member(knife, m_pPlayer)

	set_pev(pPlayer, pev_viewmodel2, MODEL_HUNTER_KNIFE);
	return HAM_IGNORED;
}

public ShowWeaponsMenu(pPlayer) {
	new iMenu = menu_create("Weapons menu", "Handler_WeaponsMenu")

	menu_additem(iMenu, "AK47")
	menu_additem(iMenu, "M249")
	menu_additem(iMenu, "AWP")

	menu_display(pPlayer, iMenu)
}

public Handler_WeaponsMenu(pPlayer, iMenu, iItem) {
	if (iItem == MENU_EXIT) goto MENU_END

	if (VM_GameStarted()) {
		client_print(pPlayer, print_chat, "[VM] Game already started.")
		goto MENU_END
	}

	switch (iItem) {
		case 0: {
			rg_give_item(pPlayer, "weapon_ak47", GT_DROP_AND_REPLACE)
			rg_set_user_bpammo( pPlayer, rg_get_weapon_info("weapon_ak47", WI_ID), 90)
		}
		case 1: {
			rg_give_item(pPlayer, "weapon_m249", GT_DROP_AND_REPLACE)
			rg_set_user_bpammo( pPlayer, rg_get_weapon_info("weapon_m249", WI_ID), 90)
		}
		case 2: {
			rg_give_item(pPlayer, "weapon_awp", GT_DROP_AND_REPLACE)
			rg_set_user_bpammo( pPlayer, rg_get_weapon_info("weapon_awp", WI_ID), 30)
		}
	}

	MENU_END:
	menu_destroy(iMenu)
}