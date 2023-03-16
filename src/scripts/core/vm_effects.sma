#include <amxmodx>
#include <fakemeta>
#include <vm_main>

#define LIGHTING_STYLE "d"

public plugin_init() {
    register_plugin("[VM] Effects", VM_VERSION, "JustGo")
}

public plugin_cfg() {
    // Lighting task
	set_task(5.0, "lighting_task", _, _, _, "b")
}

public lighting_task() {
    engfunc(EngFunc_LightStyle, 0, LIGHTING_STYLE)
}