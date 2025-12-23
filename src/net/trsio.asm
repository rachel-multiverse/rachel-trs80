; =============================================================================
; TRS-80 TRS-IO NETWORK DRIVER
; TCP/IP via TRS-IO WiFi adapter
; Port definitions in equates.asm
; =============================================================================

; TRS-IO Data port (using DATA_LO from equates)
TRSIO_DATA      equ     TRSIO_DATA_LO

; TRS-IO Commands (local to this module)
CMD_INIT        equ     $00
CMD_CONNECT     equ     $10
CMD_CLOSE       equ     $11
CMD_SEND        equ     $20
CMD_RECV        equ     $21
CMD_STATUS_CHK  equ     $30

; Status bits
STAT_READY      equ     $01
STAT_CONNECTED  equ     $02
STAT_DATA_AVAIL equ     $04
STAT_ERROR      equ     $80

; Connection state
net_state:      defb    0
NET_DISCONNECTED equ    0
NET_CONNECTING   equ    1
NET_CONNECTED    equ    2

; -----------------------------------------------------------------------------
; Initialize network
; Returns: Carry clear on success
; -----------------------------------------------------------------------------
net_init:
        ; Send init command
        ld      a, CMD_INIT
        out     (TRSIO_CMD), a

        ; Wait for ready
        call    wait_ready
        ret     c

        ; Check status
        in      a, (TRSIO_STATUS)
        and     STAT_ERROR
        jr      nz, ni_fail

        xor     a
        ld      (net_state), a
        ret                     ; Carry clear

ni_fail:
        scf
        ret

; -----------------------------------------------------------------------------
; Connect to server
; Input: server_ip = IP address, conn_port = port
; Returns: Carry clear on success
; -----------------------------------------------------------------------------
net_connect:
        ld      a, NET_CONNECTING
        ld      (net_state), a

        ; Send connect command
        ld      a, CMD_CONNECT
        out     (TRSIO_CMD), a

        ; Wait for ready to accept params
        call    wait_ready
        ret     c

        ; Send IP address (4 bytes)
        ld      hl, server_ip
        ld      b, 4
nc_ip:
        ld      a, (hl)
        out     (TRSIO_DATA), a
        inc     hl
        djnz    nc_ip

        ; Send port (2 bytes, big-endian)
        ld      a, (conn_port+1)        ; High byte
        out     (TRSIO_DATA), a
        ld      a, (conn_port)          ; Low byte
        out     (TRSIO_DATA), a

        ; Wait for connection
        call    wait_connected
        ret     c

        ld      a, NET_CONNECTED
        ld      (net_state), a
        or      a                       ; Clear carry
        ret

; -----------------------------------------------------------------------------
; Close connection
; -----------------------------------------------------------------------------
net_close:
        ld      a, CMD_CLOSE
        out     (TRSIO_CMD), a

        call    wait_ready

        xor     a
        ld      (net_state), a
        ret

; -----------------------------------------------------------------------------
; Send data
; Input: tx_buffer contains 64 bytes
; Returns: Carry clear on success
; -----------------------------------------------------------------------------
net_send:
        ld      a, (net_state)
        cp      NET_CONNECTED
        jr      nz, ns_fail

        ; Send command
        ld      a, CMD_SEND
        out     (TRSIO_CMD), a

        call    wait_ready
        jr      c, ns_fail

        ; Send length (64 bytes)
        ld      a, 64
        out     (TRSIO_DATA), a

        ; Send data
        ld      hl, tx_buffer
        ld      b, 64
ns_loop:
        ld      a, (hl)
        out     (TRSIO_DATA), a
        inc     hl
        djnz    ns_loop

        ; Wait for completion
        call    wait_ready
        ret

ns_fail:
        scf
        ret

; -----------------------------------------------------------------------------
; Receive data
; Output: rx_buffer contains data
; Returns: Carry clear if data received
; -----------------------------------------------------------------------------
net_recv:
        ld      a, (net_state)
        cp      NET_CONNECTED
        jr      nz, nr_fail

        ; Check for data available
        in      a, (TRSIO_STATUS)
        and     STAT_DATA_AVAIL
        jr      z, nr_none

        ; Send receive command
        ld      a, CMD_RECV
        out     (TRSIO_CMD), a

        call    wait_ready
        jr      c, nr_fail

        ; Request 64 bytes
        ld      a, 64
        out     (TRSIO_DATA), a

        ; Read data
        ld      hl, rx_buffer
        ld      b, 64
nr_loop:
        call    wait_data
        jr      c, nr_partial
        in      a, (TRSIO_DATA)
        ld      (hl), a
        inc     hl
        djnz    nr_loop

        or      a                       ; Clear carry
        ret

nr_partial:
        ; Fill rest with zeros
        xor     a
nr_fill:
        ld      (hl), a
        inc     hl
        djnz    nr_fill

nr_none:
nr_fail:
        scf
        ret

; -----------------------------------------------------------------------------
; Wait for ready status
; Returns: Carry set on timeout
; -----------------------------------------------------------------------------
wait_ready:
        ld      de, $FFFF               ; Timeout counter
wr_loop:
        in      a, (TRSIO_STATUS)
        and     STAT_READY
        jr      nz, wr_ok

        dec     de
        ld      a, d
        or      e
        jr      nz, wr_loop

        scf                             ; Timeout
        ret

wr_ok:
        or      a                       ; Clear carry
        ret

; -----------------------------------------------------------------------------
; Wait for connected status
; Returns: Carry set on timeout/error
; -----------------------------------------------------------------------------
wait_connected:
        ld      de, $0000               ; Long timeout (65536 iterations)
        ld      b, 10                   ; Outer loop for extended timeout
wc_outer:
        push    bc
wc_loop:
        in      a, (TRSIO_STATUS)

        ; Check for error
        and     STAT_ERROR
        jr      nz, wc_error

        in      a, (TRSIO_STATUS)
        and     STAT_CONNECTED
        jr      nz, wc_ok

        dec     de
        ld      a, d
        or      e
        jr      nz, wc_loop

        pop     bc
        djnz    wc_outer

        scf                             ; Timeout
        ret

wc_error:
        pop     bc
        scf
        ret

wc_ok:
        pop     bc
        or      a                       ; Clear carry
        ret

; -----------------------------------------------------------------------------
; Wait for data available
; Returns: Carry set on timeout
; -----------------------------------------------------------------------------
wait_data:
        push    de
        ld      de, $1000               ; Short timeout
wd_loop:
        in      a, (TRSIO_STATUS)
        and     STAT_DATA_AVAIL
        jr      nz, wd_ok

        dec     de
        ld      a, d
        or      e
        jr      nz, wd_loop

        pop     de
        scf                             ; Timeout
        ret

wd_ok:
        pop     de
        or      a                       ; Clear carry
        ret
