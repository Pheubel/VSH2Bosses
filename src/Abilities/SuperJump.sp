#pragma semicolon 1

#include "include/ConfigBoss.inc"
#include "include/VSH2Utils.inc"
#include <vsh2>

#define DEFAULT_WEIGHDOWN_TIME 2.0
#define DEFAULT_INCREASE 0.1
#define DEFAULT_POWER 1.0

ConfigMap bossConfig;
ConfigMap chargeSection;

public void OnPluginStart() {
    bossConfig = CloneBossConfigMap();
}

public void OnLibraryAdded(const char[] name) {
    if( StrEqual(name, "VSH2")) {
        if( !VSH2_HookEx(OnBossThink, HandleOnBossThink)) {
            LogError("Error loading OnBossThink forwards for superjump subplugin.");
        }
    }
}

Register_Charge_Ability {
    if(!ConfigBossHookAbility(OnChargeAbility, Jump)) {
        LogMessage("Could not hook on charge super jump ability");
    }

    chargeSection = bossConfig.GetSection(VSH_DEFAULT_SELECTOR_CHARGE_ABILITY).GetIntSection(abilitySectionIndex);
}

void Jump(const VSH2Player bossPlayer) {
    float power;
    if(chargeSection.GetFloat("power", power) == 0) {
        power = DEFAULT_POWER;
    }

    // reset timer should not have an effect due to it being set after the call
    bossPlayer.SuperJump(bossPlayer.GetPropFloat("flCharge") * power, DEFAULT_CHARGE_COOLDOWN);
}

HandleOnBossThink(const VSH2Player bossPlayer) {
    float weighDownTime, increase;
    if(chargeSection.GetFloat("weighdown time", weighDownTime) == 0) {
        weighDownTime = DEFAULT_WEIGHDOWN_TIME;
    }

    if(chargeSection.GetFloat("weighdown increase", increase) == 0) {
        increase = DEFAULT_INCREASE;
    }

    bossPlayer.WeighDownThink(weighDownTime, increase);
}