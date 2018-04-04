@echo off

rem ----------------------------------------------------------------------------
rem The following variables must be updated for the branch.
rem ----------------------------------------------------------------------------

set buildDirectory=k:\BCT_Development\optia_perforce\taos_builds
set commonBuildsDirectory=k:\BCT_Development\optia_perforce\common_builds
set rmsgBuildsDirectory=k:\BCT_Development\optia_perforce\reserved_messages_builds

rem ----------------------------------------------------------------------------
rem No modifications below this line
rem ----------------------------------------------------------------------------

echo ===============================================================
echo ---------------------------------------------------------------
echo ----------                                      ---------------
echo ----------       Optia Build Freeze Script      ---------------
echo ----------                                      ---------------
echo ---------------------------------------------------------------
echo ===============================================================
echo Are you sure you want to freeze this build area (Enter Y or N)?
set /p continue=

if "%continue%" == "y" (
	goto freeze_the_build
)

if "%continue%" == "Y" (
	goto freeze_the_build
)

if not "%continue%" == "" (
	echo Aborting freeze process.
	goto end_of_script
)

:freeze_the_build

if exist %buildDirectory%\latest_common_build_dir.mk (
	echo Common build reference already frozen
)

if not exist %buildDirectory%\latest_common_build_dir.mk (
	echo Adding common build reference
	copy /Y /V %commonBuildsDirectory%\latest_common_build_dir.mk %buildDirectory%\latest_common_build_dir.mk
)

if exist %buildDirectory%\latest_rmsg_build_dir.mk (
	echo Reserved messages build reference already frozen
)

if not exist %buildDirectory%\latest_rmsg_build_dir.mk (
	echo Adding reserved messages build reference
	copy /Y /V %rmsgBuildsDirectory%\latest_rmsg_build_dir.mk %buildDirectory%\latest_rmsg_build_dir.mk
)

echo The build area has been frozen.

:end_of_script

echo Press the Enter key to exit ...
set /p exitCode=

