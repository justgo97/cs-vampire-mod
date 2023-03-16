#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <vm_main>
#include <xs>

#define VP_CHECK_INTERVAL 3.0
#define VP_REG_INTERVAL 1.0
#define VP_REG_HEALTH 500.0

new Float:g_fLastRegenerate[MAX_PLAYERS+1];
new Float:g_fLastCheck[MAX_PLAYERS+1];
new bool:g_bRegenerating[MAX_PLAYERS+1]

public plugin_init() {
    register_plugin("[VM] Vampire regeneration", VM_VERSION, "JustGo")

    RegisterHamPlayer(Ham_Player_PostThink, "HHook_Player_PostThink_Post", .Post = 1);
}

public HHook_Player_PostThink_Post(pPlayer) {
    if (!is_user_alive(pPlayer)) return HAM_IGNORED

    if (get_member(pPlayer, m_iTeam) != TEAM_TERRORIST) return HAM_IGNORED

    new Float:fGameTime = get_gametime();

    // If we were idle regenerate health every 1 sec
    if (g_bRegenerating[pPlayer])
    {
        if (g_fLastRegenerate[pPlayer] < fGameTime) {
            static Float:fMaxHealth;
            get_entvar(pPlayer, var_max_health, fMaxHealth);

            static Float:fHealth;
            get_entvar(pPlayer, var_health, fHealth);

            if (fMaxHealth != fMaxHealth) {
                fHealth = floatmin(fHealth + VP_REG_HEALTH, fMaxHealth);
                set_entvar(pPlayer, var_health, fHealth);
            } else {
                g_bRegenerating[pPlayer] = false
            }
            g_fLastRegenerate[pPlayer] = fGameTime + VP_REG_INTERVAL;
        }

        g_fLastCheck[pPlayer] = fGameTime + VP_CHECK_INTERVAL;
    } else if (g_fLastCheck[pPlayer] < fGameTime) {
        static Float:fLastOrigin[3]
        get_entvar(pPlayer, var_vuser1, fLastOrigin)
        static Float:fCurrentOrigin[3]
        get_entvar(pPlayer, var_origin, fCurrentOrigin)

        // Player was idle for 3 seconds
        if (xs_vec_equal(fLastOrigin, fCurrentOrigin)) {
            if (get_entvar(pPlayer, var_health) != get_entvar(pPlayer, var_max_health)) {
                g_bRegenerating[pPlayer] = true
            }
        }

        set_entvar(pPlayer, var_vuser1, fCurrentOrigin)
        g_fLastCheck[pPlayer] = fGameTime + VP_CHECK_INTERVAL;
    }

    return HAM_IGNORED
}