#!/usr/bin/env bash

set -eu


declare -r CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -ne 1 ]
then
	echo "USAGE: make_proj.sh <NAME>"
	exit 1
fi

declare -r NAME="$1"
declare -r BASENAME="$(basename -- "$NAME")"

if [[ "$BASENAME" = *[!a-zA-Z_]* ]]
then
	echo "Invalid NAME"
	exit 1
fi

pushd -- "$CURRENT_DIR" >/dev/null || exit 1

mkdir -p -- "$CURRENT_DIR/$NAME"
cd -- "$CURRENT_DIR/$NAME"

>"$BASENAME.prj" cat <<-FILE
	verilog work "$BASENAME.v"
	FILE

>"$BASENAME.v" cat <<-FILE
	\`default_nettype none

	module $BASENAME (
	);

	endmodule
	FILE

>"$BASENAME.xst" cat <<-FILE
	run -ifn $BASENAME.prj -p xc3s100e-4-cp132 -top $BASENAME -ofn $BASENAME
	FILE

>"$BASENAME.ucf" cat <<-FILE
	# clock pin for Basys2 Board
	NET "mclk" LOC = "B8" | PERIOD = 20 ns; # Bank = 0, Signal name = MCLK
	NET "uclk" LOC = "M6" | PERIOD = 50 ns; # Bank = 2, Signal name = UCLK
	NET "mclk" CLOCK_DEDICATED_ROUTE = FALSE;
	NET "uclk" CLOCK_DEDICATED_ROUTE = FALSE;

	# Pin assignment for EppCtl
	# Connected to Basys2 onBoard USB controller
	#NET "EppAstb" LOC = "F2"; # Bank = 3
	#NET "EppDstb" LOC = "F1"; # Bank = 3
	#NET "EppWR"       LOC = "C2"; # Bank = 3

	#NET "EppWait" LOC = "D2"; # Bank = 3


	#NET "EppDB<0>" LOC = "N2"; # Bank = 2
	#NET "EppDB<1>" LOC = "M2"; # Bank = 2
	#NET "EppDB<2>" LOC = "M1"; # Bank = 3
	#NET "EppDB<3>" LOC = "L1"; # Bank = 3
	#NET "EppDB<4>" LOC = "L2"; # Bank = 3
	#NET "EppDB<5>" LOC = "H2"; # Bank = 3
	#NET "EppDB<6>" LOC = "H1"; # Bank = 3
	#NET "EppDB<7>" LOC = "H3"; # Bank = 3


	# Pin assignment for DispCtl
	# Connected to Basys2 onBoard 7seg display
	NET "seg<0>" LOC = "L14"; # Bank = 1, Signal name = CA
	NET "seg<1>" LOC = "H12"; # Bank = 1, Signal name = CB
	NET "seg<2>" LOC = "N14"; # Bank = 1, Signal name = CC
	NET "seg<3>" LOC = "N11"; # Bank = 2, Signal name = CD
	NET "seg<4>" LOC = "P12"; # Bank = 2, Signal name = CE
	NET "seg<5>" LOC = "L13"; # Bank = 1, Signal name = CF
	NET "seg<6>" LOC = "M12"; # Bank = 1, Signal name = CG
	NET "dp" LOC = "N13"; # Bank = 1, Signal name = DP

	NET "an<3>" LOC = "K14"; # Bank = 1, Signal name = AN3
	NET "an<2>" LOC = "M13"; # Bank = 1, Signal name = AN2
	NET "an<1>" LOC = "J12"; # Bank = 1, Signal name = AN1
	NET "an<0>" LOC = "F12"; # Bank = 1, Signal name = AN0

	# Pin assignment for LEDs
	NET "Led<7>" LOC = "G1" ; # Bank = 3, Signal name = LD7
	NET "Led<6>" LOC = "P4" ; # Bank = 2, Signal name = LD6
	NET "Led<5>" LOC = "N4" ;  # Bank = 2, Signal name = LD5
	NET "Led<4>" LOC = "N5" ;  # Bank = 2, Signal name = LD4
	NET "Led<3>" LOC = "P6" ; # Bank = 2, Signal name = LD3
	NET "Led<2>" LOC = "P7" ; # Bank = 3, Signal name = LD2
	NET "Led<1>" LOC = "M11" ; # Bank = 2, Signal name = LD1
	NET "Led<0>" LOC = "M5" ;  # Bank = 2, Signal name = LD0

	# Pin assignment for SWs
	NET "sw<7>" LOC = "N3";  # Bank = 2, Signal name = SW7
	NET "sw<6>" LOC = "E2";  # Bank = 3, Signal name = SW6
	NET "sw<5>" LOC = "F3";  # Bank = 3, Signal name = SW5
	NET "sw<4>" LOC = "G3";  # Bank = 3, Signal name = SW4
	NET "sw<3>" LOC = "B4";  # Bank = 3, Signal name = SW3
	NET "sw<2>" LOC = "K3";  # Bank = 3, Signal name = SW2
	NET "sw<1>" LOC = "L3";  # Bank = 3, Signal name = SW1
	NET "sw<0>" LOC = "P11";  # Bank = 2, Signal name = SW0

	NET "btn<3>" LOC = "A7";  # Bank = 1, Signal name = BTN3
	NET "btn<2>" LOC = "M4";  # Bank = 0, Signal name = BTN2
	NET "btn<1>" LOC = "C11"; # Bank = 2, Signal name = BTN1
	NET "btn<0>" LOC = "G12"; # Bank = 0, Signal name = BTN0

	# Loop back/demo signals
	# Pin assignment for PS2
	#NET "PS2C"    LOC = "B1"   | DRIVE = 2  | PULLUP ; # Bank = 3, Signal name = PS2C
	#NET "PS2D"    LOC = "C3"   | DRIVE = 2  | PULLUP ; # Bank = 3, Signal name = PS2D

	# Pin assignment for VGA
	#NET "HSYNC"   LOC = "J14"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = HSYNC
	#NET "VSYNC"   LOC = "K13"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = VSYNC

	#NET "OutRed<2>"  LOC = "F13"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = RED2
	#NET "OutRed<1>"  LOC = "D13"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = RED1
	#NET "OutRed<0>"  LOC = "C14"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = RED0
	#NET "OutGreen<2>"  LOC = "G14"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = GRN2
	#NET "OutGreen<1>"  LOC = "G13"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = GRN1
	#NET "OutGreen<0>"  LOC = "F14"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = GRN0
	#NET "OutBlue<2>"  LOC = "J13"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = BLU2
	#NET "OutBlue<1>"  LOC = "H13"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = BLU1

	# Loop Back only tested signals
	#NET "PIO<72>" LOC = "B2"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JA1
	#NET "PIO<73>" LOC = "A3"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JA2
	#NET "PIO<74>" LOC = "J3"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JA3
	#NET "PIO<75>" LOC = "B5"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JA4

	#NET "PIO<76>" LOC = "C6"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JB1
	#NET "PIO<77>" LOC = "B6"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JB2
	#NET "PIO<78>" LOC = "C5"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JB3
	#NET "PIO<79>" LOC = "B7"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JB4

	#NET "PIO<80>" LOC = "A9"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JC1
	#NET "PIO<81>" LOC = "B9"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JC2
	#NET "PIO<82>" LOC = "A10" | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JC3
	#NET "PIO<83>" LOC = "C9"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JC4

	#NET "PIO<84>" LOC = "C12"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JD1
	#NET "PIO<85>" LOC = "A13"  | DRIVE = 2  | PULLUP ; # Bank = 2, Signal name = JD2
	#NET "PIO<86>" LOC = "C13"  | DRIVE = 2  | PULLUP ; # Bank = 1, Signal name = JD3
	#NET "PIO<87>" LOC = "D12"  | DRIVE = 2  | PULLUP ; # Bank = 2, Signal name = JD4
	FILE

>synth.sh cat <<-FILE
	#!/usr/bin/env sh

	set -e


	# Synteza (.v -> .ngc)
	xst -ifn $BASENAME.xst
	# Linkowanie (.ngc -> .ngd)
	ngdbuild $BASENAME -uc $BASENAME.ucf
	# Tłumaczenie na prymitywy dostępne w układzie Spartan 3E (.ngd -> .ncd)
	map $BASENAME
	# Place and route (.ncd -> lepszy .ncd)
	par -w $BASENAME.ncd ${BASENAME}_par.ncd || true
	# Generowanie finalnego bitstreamu (.ncd -> .bit)
	bitgen -w ${BASENAME}_par.ncd -g StartupClk:JTAGClk
	FILE
chmod +x synth.sh

cd -- "$CURRENT_DIR/bitstreams"
ln -s -- "$CURRENT_DIR/$NAME/$BASENAME"_par.bit .

popd >/dev/null
