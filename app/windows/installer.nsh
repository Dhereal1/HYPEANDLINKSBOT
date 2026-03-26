; Custom NSIS: window title only (no " Setup" suffix).
; Workaround for intermittent NSIS self-update/uninstall failures reported by
; multiple electron-builder users on some Windows machines.
CRCCheck off

!macro customHeader
  Caption "${PRODUCT_NAME}"
!macroend

; Override process check to use quoted SYSTEMROOT-based tool paths.
; This matches a community workaround for path handling inconsistencies.
!macro customCheckAppRunning
  !define SYSTEMROOT "$%SYSTEMROOT%"
  nsExec::Exec '"${SYSTEMROOT}\System32\cmd.exe" /c tasklist /FI "USERNAME eq %USERNAME%" /FI "IMAGENAME eq ${_FILE}" /FO csv | "${SYSTEMROOT}\System32\find.exe" "${_FILE}"'
  Pop $R0
!macroend
