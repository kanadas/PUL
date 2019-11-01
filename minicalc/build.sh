#!/bin/bash
# Synteza (.v -> .ngc)
xst -ifn minicalc.xst &&\
# Linkowanie (.ngc -> .ngd)
ngdbuild minicalc -uc minicalc.ucf &&\
# Tłumaczenie na prymitywy dostępne w układzie Spartan 3E (.ngd -> .ncd)
map minicalc &&\
# Place and route (.ncd -> lepszy .ncd)
par -w minicalc.ncd minicalc.ncd &&\
# Generowanie finalnego bitstreamu (.ncd -> .bit)
bitgen -w minicalc.ncd -g StartupClk:JTAGClk
