@Echo off
setlocal ENABLEDELAYEDEXPANSION
:: Delayed Expansion Needed for multi-line variable input for domainStat

:: Check if Bitlocker Enabled, bitStat 1-True 0-False
for /f "delims=" %%A in ('manage-bde -status ^| find "Protection Status"') do set "varTest=%%A"
ECHO.%varTest%| FIND /I "Protection On">Nul && (
set bitStat=1
) || (
set bitStat=0
)

:: Check if Domain Controller Trusted/Reachable, domainStat 1-True 0-False
for /f "delims=" %%A in ('nltest /server:%COMPUTERNAME% /sc_query:simis.loc') do set "varTest2=!varTest2!%%A"
ECHO.!varTest2!| FIND /I "NERR_Success">Nul && (
set domainStat=1
) || (
set domainStat=0
)

:: If Domain Reachable
if %domainStat% == 1 (
    :: Create 48 Digit Random Key
    manage-bde -protectors -add %systemdrive% -RecoveryPassword
    :: Backup to Active Directory
    for /F "tokens=2 delims=: " %%C in ('manage-bde -protectors -get %systemdrive% -type ^
    recoverypassword ^| findstr " ID:"') do set "varID=!varID!%%C"
    manage-bde -protectors -adbackup %systemdrive% -id !varID!
    :: If BitLocker Not Already Running
    if %bitStat% == 0 (
        :: Enable Key and Bitlocker
        manage-bde -protectors -enable %systemdrive%
        manage-bde -on %systemdrive%
    )
    GOTO :breakEnableStatement
) ELSE (
:: If Errors, Display Debug
ECHO.Device Not Ready
ECHO.BitLocker Status %bitStat%
ECHO.Domain Status %domainStat%
)
:breakEnableStatement