#if defined _vm_main_included
  #endinput
#endif
#define _vm_main_included

#define VM_VERSION "0.0.1"

#define m_bDontRespawn m_bReceivesNoMoneyNextRound

#include <vm_resources>


native VM_GameStarted();

native VM_SetVampire(pPlayer);

native VM_GetRage();