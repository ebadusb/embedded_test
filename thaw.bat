@echo off

rem ----------------------------------------------------------------------------
rem The following variables must be updated for the branch.
rem ----------------------------------------------------------------------------

set buildDirectory=k:\BCT_Development\optia_perforce\taos_builds

rem ----------------------------------------------------------------------------
rem No modifications below this line
rem ----------------------------------------------------------------------------

echo =============================================================
echo -------------------------------------------------------------
echo ----------                                    ---------------
echo ----------       Optia Build Thaw Script      ---------------
echo ----------                                    ---------------
echo -------------------------------------------------------------
echo =============================================================
echo Are you sure you want to thaw this build area (Enter Y or N)?
set /p continue=

if "%continue%" == "y" (
	goto thaw_the_build
)

if "%continue%" == "Y" (
	goto thaw_the_build
)

if not "%continue%" == "" (
	echo Aborting thaw process.
	goto end_of_script
)

:thaw_the_build

if exist %buildDirectory%\latest_common_build_dir.mk (
	echo Removing common build reference
	rm -f %buildDirectory%\latest_common_build_dir.mk
)

if exist %buildDirectory%\latest_rmsg_build_dir.mk (
	echo Removing reserved messages build reference
	rm -f %buildDirectory%\latest_rmsg_build_dir.mk
)

echo The build area has been thawed.

:end_of_script

echo Press the Enter key to exit ...
set /p exitCode=

