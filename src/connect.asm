; =============================================================================
; TRS-80 CONNECTION MODULE
; =============================================================================

; -----------------------------------------------------------------------------
; Connect to game server
; Input: HL = hostname string, DE = port
; Returns: Carry set on error
; -----------------------------------------------------------------------------
connect_server:
        ld      (conn_port), de

        ; Initialize network
        call    net_init
        ret     c

        ; Parse IP address
        call    parse_ip
        ret     c

        ; Open TCP connection
        call    net_connect
        ret     c

        ; Connection established
        ld      a, 1
        ld      (connected), a
        or      a               ; Clear carry
        ret

conn_port:      defw    0
connected:      defb    0

; -----------------------------------------------------------------------------
; Disconnect from server
; -----------------------------------------------------------------------------
disconnect:
        ld      a, (connected)
        or      a
        ret     z

        call    net_close
        xor     a
        ld      (connected), a
        ret

; -----------------------------------------------------------------------------
; Parse IP address from string
; Input: HL = string "n.n.n.n"
; Output: server_ip filled
; -----------------------------------------------------------------------------
parse_ip:
        ld      de, server_ip
        ld      b, 4            ; 4 bytes

pi_byte:
        xor     a
        ld      c, a            ; Accumulator

pi_digit:
        ld      a, (hl)
        or      a
        jr      z, pi_end_byte
        cp      '.'
        jr      z, pi_next
        cp      ':'
        jr      z, pi_end_byte
        cp      '0'
        jr      c, pi_error
        cp      ':'
        jr      nc, pi_error

        ; Digit 0-9
        sub     '0'
        push    af
        ld      a, c
        add     a, a            ; *2
        add     a, a            ; *4
        add     a, c            ; *5
        add     a, a            ; *10
        ld      c, a
        pop     af
        add     a, c
        ld      c, a

        inc     hl
        jr      pi_digit

pi_next:
        ld      a, c
        ld      (de), a
        inc     de
        inc     hl
        dec     b
        jr      nz, pi_byte
        jr      pi_error

pi_end_byte:
        ld      a, c
        ld      (de), a
        inc     de
        dec     b
        jr      z, pi_done

        ; Fill remaining with zeros
pi_fill:
        xor     a
        ld      (de), a
        inc     de
        djnz    pi_fill

pi_done:
        or      a               ; Clear carry
        ret

pi_error:
        scf
        ret

server_ip:      defb    0, 0, 0, 0

; -----------------------------------------------------------------------------
; Show connection screen
; -----------------------------------------------------------------------------
show_connect_screen:
        call    display_init

        ld      h, 20
        ld      l, 4
        call    set_cursor
        ld      hl, cs_title
        call    print_string

        ld      h, 16
        ld      l, 6
        call    set_cursor
        ld      hl, cs_prompt
        call    print_string

        ld      h, 16
        ld      l, 8
        call    set_cursor

        ret

cs_title:   defb    "CONNECT TO RACHEL", 0
cs_prompt:  defb    "SERVER IP: ", 0

; -----------------------------------------------------------------------------
; Get server address from user
; Returns: Carry set if cancelled
; -----------------------------------------------------------------------------
get_server_address:
        call    show_connect_screen

        ; Input IP address
        ld      hl, input_buffer
        ld      b, 15
        call    input_line

        or      a
        jr      z, gsa_cancel

        ; Parse and store
        ld      hl, input_buffer
        call    parse_ip
        ret     c

        or      a               ; Clear carry
        ret

gsa_cancel:
        scf
        ret

input_buffer:   defs    16, 0

; -----------------------------------------------------------------------------
; Show connecting message
; -----------------------------------------------------------------------------
show_connecting:
        ld      h, 22
        ld      l, 10
        call    set_cursor
        ld      hl, sc_msg
        call    print_string
        ret

sc_msg: defb    "CONNECTING...", 0

; -----------------------------------------------------------------------------
; Show connection error
; -----------------------------------------------------------------------------
show_connect_error:
        ld      h, 18
        ld      l, 10
        call    set_cursor
        ld      hl, sce_msg
        call    print_string
        call    wait_key
        ret

sce_msg:    defb    "CONNECTION FAILED!", 0
