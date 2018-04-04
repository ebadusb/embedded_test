**********************************************
*                                            *
*                                            *
*    Perforce auto build process             *
*                                            *
*                                            *
**********************************************

These scripts can run a taos build from any machine

This script is meant for QA builds only. Please do not use for local builds.
Doing so will mess up the build label sequence.

These scripts will need to be modified whenever taos codeline is branched.

-----------------------------------------------

Make sure that K:\ is mapped to \\bctquad3\home

Reserved Messages builds -> K:\Bct_development\reserved_messages_perforce_builds
Common builds -> K:\Bct_development\optia_perforce\common_builds
Taos builds -> K:\Bct_development\optia_perforce\taos_builds

There are three scripts that QA should use.

1. autobuild_rmsg.bat  - Checkpoint's the reserved messages project and does a QA build, creating a label
"reserved_messages_build_x.xx"

2. autobuild_common.bat  - Checkpoint's the common project and does a QA build, creating a label "common_build_x.xx"

   - By default the autobuild script forces common to use latest rmsg build.
   
   - It can be forced to use a specific rmsg build by modifying rmsgDirectory variable at top of script.

3. autobuild_taos.bat    - Checkpoint's the Taos project and does a QA build, creating a label "optia_build_x.xx"

   - By default the autobuild script forces taos to use latest rmsg & common builds

   - It can be forced to use a specific rmsg & common builds by using freeze.bat & thaw.bat scripts.

These labels can be changed at any point of time.
Please do not modify other files in this directory. If you feel the need, please talk to Mark Scott { ex 2258 }

------------------------------------------------

Make sure that K:\ is mapped to \\bctquad3\home . Else the scripts will not work.

If k:\ is mapped differently on your local machine, you will need to modify local copies of the following files.
- taos/makefile.fc
- autobuild_common.bat
- autobuild_taos.bat
- common_wsp_template.tmp
- optia_swqa_template.tmp
- freeze.bat
- thaw.bat

--------------------------------------------------

The scripts assume tornado dir to e c:\tornado2.2. If that is different please change this section

rem Point torvarsDirectory to the dir where Torvars.bat is located on build machine.
set torvarsDirectory=C:\Tornado2.2\host\x86-win32\bin
set torvarsScript=torVars.bat

in the follwing files
- autobuild_common.bat
- autobuild_taos.bat

--------------------------------------------------



