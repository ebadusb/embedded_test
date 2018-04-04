@echo off

rem ----------------------------------------------------------------------------
rem - The following variables must be updated for the branch.
rem - Note: the following variables must be provided by the build environment
rem - if this is a fully automated build:
rem -    AUTOBUILD: Set to any value
rem -    WORKSPACE: The P4 workspace containing the autobuild tools.
rem -    NEWVERSION: The desired build number.
rem ----------------------------------------------------------------------------

set buildScript=create_common.bat
rem An automation environment like Jenkins may specify the AUTOBUILD variable.
if "" == "%AUTOBUILD%" (
   set sandboxDirectory=c:\common_build
) else (
   set sandboxDirectory=%WORKSPACE%\common_build
)
set residue=%sandboxDirectory%\residue_common
set buildDirectory=k:\BCT_Development\optia_perforce\common_builds
set rmsgDirectory=k:\BCT_Development\reserved_messages_perforce_builds
set perforce_tools=.

rem Point torvarsDirectory to the dir where Torvars.bat is located on build machine.
set torvarsDirectory=C:\Tornado2.2\host\x86-win32\bin
set torvarsScript=torVars.bat

rem ----------------------------------------------------------------------------
rem
rem
rem   ********   No modifications below this line ********
rem
rem
rem ----------------------------------------------------------------------------

echo.
echo.
echo ===============================================================
echo ---------------------------------------------------------------
echo ----------                                      ---------------
echo ----------         Optia Autobuild Script       ---------------
echo ----------                                      ---------------
echo ---------------------------------------------------------------
echo ===============================================================
echo.
echo.

set startDate=%date%
set startTime=%time%

p4 set P4HOST=%COMPUTERNAME%
P4 set P4PORT=usbsrdcms01:1666

rem ----------------------------------------------------------------------------
rem
rem        Login to Perforce. Prompt for username and password 
rem
rem ----------------------------------------------------------------------------

if "" == "%AUTOBUILD%" (
   echo Please enter perforce user name
   set /p user_name=
) else (
   set user_name=%P4USER%
)

if "" == "%AUTOBUILD%" (
   P4 -u %user_name% login
) else (
   echo %P4PASSWD%|P4 -u %user_name% login
)

if %ERRORLEVEL% GTR 0 (
   echo Either User %user_name% does not exist or password entered is incorrect
   goto end_of_script
) else (
   echo Logged in with user %user_name%
)

rem ----------------------------------------------------------------------------
rem        Clean up directories from previous build
rem ----------------------------------------------------------------------------

echo.
echo Cleaning up directories from previous build. Please wait ...


if exist %sandboxDirectory% ( 
   rmdir /S /Q %sandboxDirectory%
)

mkdir %sandboxDirectory%

echo Done !
echo.
echo.

if not exist %sandboxDirectory% (
	echo ERROR: Unable to create sandbox directory "%sandboxDirectory%".
	goto end_of_script
)

mkdir %residue%

rem If this is an autobuild, the build number is already supplied in NEWVERSION.
if "" == "%AUTOBUILD%" (
   echo Enter build number ( #.# )
   set /p build=
) else (
   echo Building %NEWVERSION%
   SET build=%NEWVERSION%
)

rem ----------------------------------------------------------------------------
rem        Check if the build number is empty
rem ----------------------------------------------------------------------------

if "%build%" == "" ( 
	echo ERROR: Invalid build number "%build%".
	goto end_of_script
)

rem ----------------------------------------------------------------------------
rem         Check if the build number contains numbers
rem ----------------------------------------------------------------------------

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

rem ----------------------------------------------------------------------------
rem
rem        Check if the label is currently in use
rem
rem ----------------------------------------------------------------------------

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

rem -------------------------------------------------------------------------
rem
rem         Flag for confirming the build process. 
rem         Check if the build number is empty.
rem
rem -------------------------------------------------------------------------
set continue=n

if "%build%" == "" ( 
	echo ERROR: Invalid build number "%build%".
	goto end_of_script
)

rem ----------------------------------------------------------------------------
rem Display the build number.
rem ----------------------------------------------------------------------------

echo Build Number: %build%

rem ----------------------------------------------------------------------------
rem         Prompt to continue the build process.
rem ----------------------------------------------------------------------------

:prompt_for_build
if "" == "%AUTOBUILD%" (
   echo Continue with build (Enter Y or N)
   set /p continue=
) else (
   goto begin_the_build
)

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

rem ----------------------------------------------------------------------------
rem
rem         Set perforce variables
rem
rem ----------------------------------------------------------------------------

:begin_the_build

set workspace=%residue%\workspace.tmp
set common_workspace=%residue%\common_workspace.tmp
set rmsg_workspace=%residue%\rmsg_workspace.tmp

rem ----------------------------------------------------------------------------
rem Mark date and time at the start of the build
rem ----------------------------------------------------------------------------

set buildStartDate=%date%
set buildStartTime=%time%

set current_build_label=common_build_%build%
echo Current build is "%current_build_label%"

rem ----------------------------------------------------------------------------
rem
rem        Use latest rmsg if it's not been frozen
rem
rem ----------------------------------------------------------------------------

set rmsgBuildLocation=""
if not exist %buildDirectory%\latest__build_dir.mk goto LatestRmsg

:FrozenRmsg
for /F %%a in (%buildDirectory%\latest_rmsg_build_dir.mk) do set rmsgBuildLocation=%%a
echo Using frozen rmsg build
goto CopyRmsg 

:LatestRmsg
for /F %%a in (%rmsgDirectory%\latest_rmsg_build_dir.mk) do set rmsgBuildLocation=%%a
echo Using latest rmsg build

:CopyRmsg
for /f "tokens=* delims=.\ " %%a in ("%rmsgBuildLocation%") do set rmsgBuildLocation=%%a
set localRmsgDir=%sandboxDirectory%\rmsg_%rmsgBuildLocation%
if exist %localRmsgDir% rmdir /S /Q %localRmsgDir%
mkdir %localRmsgDir%
echo Copying rmsg build from %rmsgDirectory%\%rmsgBuildLocation% to %localRmsgDir% ...
xcopy %rmsgDirectory%\%rmsgBuildLocation% %localRmsgDir% /E /V /F >> %sandboxDirectory%\perforce.log 2>&1    
echo %localRmsgDir% > %sandboxDirectory%\latest_rmsg_build_dir.mk

rem ----------------------------------------------------------------------------
rem
rem         Create taos sandbox with latest files from depot
rem
rem ----------------------------------------------------------------------------
call %perforce_tools%\batch_substitute.bat UUUU %user_name% %perforce_tools%\common_wsp_template.tmp > %workspace%
P4 -u %user_name% client -i < %workspace%
P4 set P4CLIENT=optia_swqa_common
P4 -u %user_name% sync -f >> %sandboxDirectory%\perforce.log 2>&1

rem ----------------------------------------------------------------------------
rem
rem         Create taos build label using label template
rem
rem ----------------------------------------------------------------------------
del /F /Q %sandboxDirectory%\project_revision
call %perforce_tools%\batch_substitute.bat BB %build% %perforce_tools%\project_revision.tmp > %sandboxDirectory%\project_revision

call %perforce_tools%\batch_substitute.bat LLLL %current_build_label% %perforce_tools%\common_label_template.tmp > %residue%\label_1.tmp
call %perforce_tools%\batch_substitute.bat UUUU %user_name% %residue%\label_1.tmp > %residue%\label_2.tmp
call %perforce_tools%\batch_substitute.bat BBB %build% %residue%\label_2.tmp > %residue%/common_label.tmp

P4  label -i < %residue%/common_label.tmp

P4  label -o %current_build_label% >> %sandboxDirectory%\perforce.log 2>&1

P4  -u %user_name% label -o %current_build_label% >> %sandboxDirectory%\perforce.log 2>&1
P4  -u %user_name% tag -l %current_build_label% //optia_swqa_common//build_%build%/... >> %sandboxDirectory%\perforce.log 2>&1

rem ----------------------------------------------------------------------------
rem
rem         Log changes since prev build
rem
rem ----------------------------------------------------------------------------

if "%prev_build_exists%"=="true" (
echo Logging changes from prev build in file_differences.txt >> %sandboxDirectory%\perforce.log 2>&1
P4  -u %user_name% diff2 -u //depot/main/Embedded/Common/...@%current_build_label% //depot/main/Embedded/Common/...@%prev_build_label%  >> %sandboxDirectory%\perforce.log 2>&1
P4  -u %user_name% diff2 -u //depot/main/Embedded/Common/...@%current_build_label% //depot/main/Embedded/Common/...@%prev_build_label% > %sandboxDirectory%\file_differences.txt
)
echo %current_build_label% > %current_build%

rem ----------------------------------------------------------------------------
rem
rem        Build the project.
rem
rem ----------------------------------------------------------------------------
echo Building Common project 
echo Building Common project >> %sandboxDirectory%\create.log 

pushd %sandboxDirectory%

rem ----------------------------------------------------------------------------
rem
rem        Set the Torvars variables
rem
rem ----------------------------------------------------------------------------

echo Setting the Torvars variables
echo Setting the Torvars variables >> %sandboxDirectory%\create.log
@echo on
call %torvarsDirectory%\%torvarsScript% 
@echo off

rem ----------------------------------------------------------------------------
rem
rem         Start the build 
rem
rem ----------------------------------------------------------------------------

attrib -r *.* /s /d
call %buildScript% >> %sandboxDirectory%\create.log 2>&1 

if %ERRORLEVEL% GTR 0 (
	cd ..
	echo ERROR: %ERRORLEVEL% Unable to build the project.
	goto mark_as_busted
)

set buildEndDate=%date%
set buildEndTime=%time%

if exist %residue% (
    rmdir /S /Q %residue%
)

goto CopyBuild

rem ----------------------------------------------------------------------------
rem
rem         Copy local built sandbox to bctquad3 optia build area
rem
rem ----------------------------------------------------------------------------

:CopyBuild

echo Build complete. Now copying sandbox to %buildDirectory%\build_%build% ...
echo Build complete. Now copying sandbox to %buildDirectory%\build_%build% ... >> %sandboxDirectory%\create.log 2>&1

popd

if exist %buildDirectory%\build_%build% (
rmdir /S /Q %buildDirectory%\build_%build%
)
mkdir %buildDirectory%\build_%build%
xcopy %sandboxDirectory% %buildDirectory%\build_%build% /E /V /F >> copy.log 2>&1

rem Get rid of existing marker file, write a new one with the network location.
if exist %buildDirectory%\latest_common_build_dir.mk (
   del /F /Q %buildDirectory%\latest_common_build_dir.mk
)
echo .\build_%build%>>%buildDirectory%\latest_common_build_dir.mk


if %ERRORLEVEL% GTR 0 (
    echo Unable to copy to Build directory : %errorLevel%
    goto end_of_script
)

echo Sandbox Start   : %startDate%, %startTime% >> copy.log 2>&1
echo Build Start     : %buildStartDate%, %buildStartTime% >> copy.log 2>&1
echo Build End       : %buildEndDate%, %buildEndTime% >> copy.log 2>&1
echo Copy complete   : %date%, %time% >> copy.log 2>&1
type copy.log >> %buildDirectory%\build_%build%\create.log
goto removeClient

rem ----------------------------------------------------------------------------
rem
rem         Mark the sanbox directory as busted.
rem
rem ----------------------------------------------------------------------------

:mark_as_busted

echo Build busted ! Now copying sandbox to %buildDirectory%\build_%build%_busted ...
echo Build busted ! Now copying sandbox to %buildDirectory%\build_%build%_busted ... >> %sandboxDirectory%\create.log 2>&1

popd

if exist %buildDirectory%\build_%build%_busted (
rmdir /S /Q %buildDirectory%\build_%build%_busted
)

mkdir %buildDirectory%\build_%build%_busted
xcopy %sandboxDirectory% %buildDirectory%\build_%build%_busted /E /V /F >> copy.log 2>&1

if %ERRORLEVEL% GTR 0 (
    echo Unable to copy to Build directory : %errorLevel%
    goto end_of_script
)

echo Sandbox Start   : %startDate%, %startTime% >> copy.log 2>&1
echo Build Start     : %buildStartDate%, %buildStartTime% >> copy.log 2>&1
echo Build End       : %buildEndDate%, %buildEndTime% >> copy.log 2>&1
echo Copy complete   : %date%, %time% >> copy.log 2>&1
type copy.log >> %buildDirectory%\build_%build%_busted\create.log

goto removeClient

rem ----------------------------------------------------------------------------
rem
rem    It is crucial to delete the client. If you don't, at the next build files from prev build 
rem    will be deleted from build dir. We still have labels but we lose copy of build.
rem
rem ----------------------------------------------------------------------------

:removeClient
p4 workspace -d optia_swqa_common

:end_of_script
popd
p4 logout
echo Build process complete.
if "" == "%AUTOBUILD%" (
   echo  Press the Enter key to exit ...
   set /p exitCode=
)
