#!/usr/bin/env sh

set -e


# Synteza (.v -> .ngc)
xst -ifn space_invaders.xst
# Linkowanie (.ngc -> .ngd)
ngdbuild space_invaders -uc space_invaders.ucf
# Tłumaczenie na prymitywy dostępne w układzie Spartan 3E (.ngd -> .ncd)
map space_invaders
# Place and route (.ncd -> lepszy .ncd)
par -w space_invaders.ncd space_invaders_par.ncd || true
# Generowanie finalnego bitstreamu (.ncd -> .bit)
bitgen -w space_invaders_par.ncd -g StartupClk:JTAGClk
