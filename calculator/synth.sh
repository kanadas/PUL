#!/usr/bin/env sh

set -e


# Synteza (.v -> .ngc)
xst -ifn calculator.xst
# Linkowanie (.ngc -> .ngd)
ngdbuild calculator -uc calculator.ucf
# Tłumaczenie na prymitywy dostępne w układzie Spartan 3E (.ngd -> .ncd)
map calculator
# Place and route (.ncd -> lepszy .ncd)
par -w calculator.ncd calculator_par.ncd || true
# Generowanie finalnego bitstreamu (.ncd -> .bit)
bitgen -w calculator_par.ncd -g StartupClk:JTAGClk
