#!/usr/bin/env sh

set -e


# Synteza (.v -> .ngc)
xst -ifn stopwatch.xst
# Linkowanie (.ngc -> .ngd)
ngdbuild stopwatch -uc stopwatch.ucf
# Tłumaczenie na prymitywy dostępne w układzie Spartan 3E (.ngd -> .ncd)
map stopwatch
# Place and route (.ncd -> lepszy .ncd)
par -w stopwatch.ncd stopwatch_par.ncd || true
# Generowanie finalnego bitstreamu (.ncd -> .bit)
bitgen -w stopwatch_par.ncd -g StartupClk:JTAGClk
