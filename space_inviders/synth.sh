#!/usr/bin/env sh

set -e


# Synteza (.v -> .ngc)
xst -ifn space_inviders.xst
# Linkowanie (.ngc -> .ngd)
ngdbuild space_inviders -uc space_inviders.ucf
# Tłumaczenie na prymitywy dostępne w układzie Spartan 3E (.ngd -> .ncd)
map space_inviders
# Place and route (.ncd -> lepszy .ncd)
par -w space_inviders.ncd space_inviders_par.ncd || true
# Generowanie finalnego bitstreamu (.ncd -> .bit)
bitgen -w space_inviders_par.ncd -g StartupClk:JTAGClk
