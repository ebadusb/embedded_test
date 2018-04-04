@echo off

rem ----------------------------------------------------------------------------
rem The following variables must be updated for the branch.
rem ----------------------------------------------------------------------------

set buildScript=create_taos.bat
set residue=k:\BCT_Development\optia_perforce\residue_taos
set buildDirectory=k:\BCT_Development\optia_perforce\taos_builds
set commonDirectory=k:\BCT_Development\optia_perforce\common_builds
set rmsgDirectory=k:\BCT_Development\reserved_messages_perforce_builds
set perforce_tools=.

rem Point torvarsDirectory to the dir where Torvars.bat is located on build machine.
set torvarsDirectory=C:\Tornado2.2\host\x86-win32\bin
set torvarsScript=torVars.bat

rem ----------------------------------------------------------------------------
rem No modifications below this line
rem ----------------------------------------------------------------------------

echo ===============================================================
echo ---------------------------------------------------------------
echo ----------                                      ---------------
echo ----------         Optia Autobuild Script       ---------------
echo ----------                                      ---------------
echo ---------------------------------------------------------------
echo ===============================================================

p4 set P4HOST=%COMPUTERNAME%

if not exist %residue% (
    mkdir %residue%
)

echo Enter build number ( #.# ):
set /p build=

rem Check if the build number is empty.
if "%build%" == "" ( 
	echo ERROR: Invalid build number "%build%".
	goto end_of_script
)

rem Check if the build number contains numbers
set buildInput=%residue%\buildInput
set containsNo=%residue%\containsNo

echo %build% > %buildInput%
findstr [0-9] %buildInput% > %containsNo%

for %%A in (%containsNo%) do ( 
    if %%~zA==0 (
        echo Invalid Build no. "%build%".
        goto end_of_script
    ) else (
        echo Valid Build no.
    )
)

rem Check if the label is currently in use
set prev_build_exists=false
setlocal enabledelayedexpansion
set current_build=%buildDirectory%/current_build.info

set current_build_label=optia_build_%build%
echo Current build is "%current_build_label%"

set filemask=%residue%\labels.tmp
p4 labels -e %current_build_label% > %filemask%

for %%A in (%filemask%) do ( 
    if %%~zA==0 (
        echo Build label %current_build_label% does not exist.
        goto checkCurrentBuild
    ) else (
        echo Build label %current_build_label% exists in perforce. Please specify a new one
        goto end_of_script
    )
)

:checkCurrentBuild
if NOT EXIST %current_build% goto buildSandbox

set /a counter=0
set prev_build_label=0

for /f %%a in (%current_build%) do (
if "!counter!"=="1" goto endLoop
set prev_build_label=%%a
set /a counter+=1
)

:endLoop
set prev_build_exists=true
echo Prev build is "%prev_build_label%"

:buildSandbox

rem The following are the project and sandbox files.
set sandboxDirectory=%buildDirectory%\build_%build%

rem Flag for confirming the build process.
set continue=n

rem Check if the build number is empty.
if "%build%" == "" ( 
	echo ERROR: Invalid build number "%build%".
	goto end_of_script
)

rem Check if the directory already exists.
if exist %sandboxDirectory% (
	echo ERROR: The sandbox directory already exists "%sandboxDirectory%".
	goto end_of_script
)

rem Check if the busted directory already exists.
if exist %sandboxDirectory%_busted (
	echo ERROR: The sandbox directory already exists "%sandboxDirectory%_busted".
	goto end_of_script
)

rem Display the build number.
echo Build Number: %build%

rem Prompt to continue the build process.
:prompt_for_build
echo Continue with build (Enter Y or N)? 
set /p continue=

if "%continue%" == "y" (
	goto begin_the_build
)

if "%continue%" == "Y" (
	goto begin_the_build
)

if not "%continue%" == "" (
	goto end_of_script
)

rem Invalid character; ask again.
goto prompt_for_build

rem Begin the build process.
:begin_the_build

rem Set perforce variables
P4 set P4PORT=usbsrdcms01:1666

set user_name=%USERNAME%
echo Please enter perforce user name
set /p user_name=
P4 -u %user_name% login

if ERRORLEVEL 1 (
   echo Either User %user_name% does not exist or password entered is incorrect
   goto end_of_script
) else (
   echo Logged in with user %user_name%
)

P4 set P4USER=%user_name%
set workspace_1=%residue%\workspace_1.tmp
set workspace=%residue%\workspace.tmp

rem Mark date and time at the start of the build
set buildStartDate=%date%
set buildStartTime=%time%

rem Create the directory for the sandbox project.
mkdir %sandboxDirectory%
if not exist %sandboxDirectory% (
	echo ERROR: Unable to create sandbox directory "%sandboxDirectory%".
	goto end_of_script
)

set current_build_label=optia_build_%build%
echo Current build is "%current_build_label%"
call %perforce_tools%\batch_substitute.bat BBB %build% %perforce_tools%\optia_swqa_template.tmp > %workspace_1%
call %perforce_tools%\batch_substitute.bat UUUU %user_name% %workspace_1% > %workspace%

P4 -u %user_name% client -i < %workspace%
P4 set P4CLIENT=optia_swqa

P4 -u %user_name% sync -f >> %sandboxDirectory%\perforce.log 2>&1

rem create project_revision file for QA build
rm -f %sandboxDirectory%\project_revision
call %perforce_tools%\batch_substitute.bat BB %build% %perforce_tools%\project_revision.tmp > %sandboxDirectory%\project_revision

call %perforce_tools%\batch_substitute.bat LLLL %current_build_label% %perforce_tools%\optia_label_template.tmp > %residue%\label_1.tmp
call %perforce_tools%\batch_substitute.bat UUUU %user_name% %residue%\label_1.tmp > %residue%\label_2.tmp
call %perforce_tools%\batch_substitute.bat BBB %build% %residue%\label_2.tmp > %residue%/optia_label.tmp

P4  label -i < %residue%/optia_label.tmp

P4  label -o %current_build_label% >> %sandboxDirectory%\perforce.log 2>&1

P4  -u %user_name% label -o %current_build_label% >> %sandboxDirectory%\perforce.log 2>&1
P4  -u %user_name% tag -l %current_build_label% //optia_swqa/build_%build%/...   >> %sandboxDirectory%\perforce.log 2>&1

if "%prev_build_exists%"=="true" ( 
echo Logging changes from prev build in file_differences.txt >> %sandboxDirectory%\perforce.log 2>&1
P4  -u %user_name% diff2 -u //depot/main/Embedded/Taos/taos/...@%current_build_label% //depot/main/Embedded/Taos/taos...@%prev_build_label% > %sandboxDirectory%\file_differences.txt
)

echo %current_build_label% > %current_build%

rem Build the project.
echo Building Taos project 
echo Building Taos project >> %sandboxDirectory%\create.log 

pushd %sandboxDirectory%

rem Set the Torvars variables
echo Setting the Torvars variables
echo Setting the Torvars variables >> %sandboxDirectory%\create.log
@echo on
call %torvarsDirectory%\%torvarsScript% 
@echo off

if not exist %buildDirectory%\latest_common_build_dir.mk (
	echo Common code: >> %sandboxDirectory%\create.log
	echo Using latest common build >> %sandboxDirectory%\create.log
)

set awkCommonInput='{ print "%commonDirectory%\"$2 }'
set awkCommonInput=%awkCommonInput:\=\\\%

if exist %buildDirectory%\latest_common_build_dir.mk (
	echo Latest common build directory specified.
	awk -F\ %awkCommonInput% < %buildDirectory%\latest_common_build_dir.mk > %sandboxDirectory%\latest_common_build_dir.mk
	echo Common code: >> %sandboxDirectory%\create.log
	cat %sandboxDirectory%\latest_common_build_dir.mk >> %sandboxDirectory%\create.log
)

if not exist %buildDirectory%\latest_rmsg_build_dir.mk (
	echo Reserved messages: >> %sandboxDirectory%\create.log
	echo Using latest reserved messages build >> %sandboxDirectory%\create.log
)

set awkReservedMessagesInput='{ print "%rmsgDirectory%\"$2 }'
set awkReservedMessagesInput=%awkReservedMessagesInput:\=\\\%

if exist %buildDirectory%\latest_rmsg_build_dir.mk (
	echo Latest reserved messages build directory specified.
	awk -F\ %awkReservedMessagesInput% < %buildDirectory%\latest_rmsg_build_dir.mk > %sandboxDirectory%\latest_rmsg_build_dir.mk
	echo Reserved messages: >> %sandboxDirectory%\create.log
	cat %sandboxDirectory%\latest_rmsg_build_dir.mk >> %sandboxDirectory%\create.log
)

rem Make sure all directories are R/W under build path. by default perforce makes them RO
attrib -r *.* /s /d
call %buildScript% >> %sandboxDirectory%\create.log 2>&1 
if ERRORLEVEL 1 (
	cd ..
	echo ERROR: Unable to build the project.
	goto mark_as_busted
)
echo Build start time %buildStartDate%, %buildStartTime% >> %sandboxDirectory%\create.log 2>&1
echo Build end time %date%, %time% >> %sandboxDirectory%\create.log 2>&1
cd ..
goto removeClient

rem Mark the sanbox directory as busted.
:mark_as_busted
echo Build start time %buildStartDate%, %buildStartTime% >> %sandboxDirectory%\create.log 2>&1
echo Build end time %date%, %time% >> %sandboxDirectory%\create.log 2>&1
ren %sandboxDirectory% %sandboxDirectory%_busted 
goto removeClient

rem    It is crucial to delete the client. If you don't, at the next build files from prev build 
rem    will be deleted from build dir. We still have labels but we lose copy of build.
:removeClient
p4 workspace -d optia_swqa

:end_of_script
if exist %residue% (
rmdir /S /Q %residue%
)
popd
echo Press the Enter key to exit ...
set /p exitCode=

