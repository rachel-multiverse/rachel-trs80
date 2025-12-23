; =============================================================================
; TRS-80 EQUATES
; =============================================================================

; Video memory
VIDEO_BASE      equ     $3C00           ; 64x16 display
VIDEO_WIDTH     equ     64
VIDEO_HEIGHT    equ     16

; Keyboard
KBDRAM          equ     $3800           ; Keyboard matrix

; Key codes
KEY_LEFT        equ     $08             ; Backspace/Left
KEY_RIGHT       equ     $09             ; Tab/Right
KEY_UP          equ     $5B             ; Up arrow
KEY_DOWN        equ     $0A             ; Down/LF
KEY_RETURN      equ     $0D
KEY_SPACE       equ     $20
KEY_BREAK       equ     $01             ; Break key
KEY_D           equ     'D'
KEY_d           equ     'd'

; TRS-IO Ports
TRSIO_CMD       equ     $31             ; Command port
TRSIO_DATA_LO   equ     $32             ; Data low
TRSIO_DATA_HI   equ     $33             ; Data high
TRSIO_STATUS    equ     $37             ; Status port

; TRS-IO Commands
TRSIO_TCP_CONN  equ     $01
TRSIO_TCP_SEND  equ     $02
TRSIO_TCP_RECV  equ     $03
TRSIO_TCP_CLOSE equ     $04
TRSIO_TCP_STAT  equ     $05

; RUBP Protocol Constants
MAGIC_0         equ     'R'
MAGIC_1         equ     'A'
MAGIC_2         equ     'C'
MAGIC_3         equ     'H'
PROTOCOL_VER    equ     1

; Header offsets
HDR_MAGIC       equ     0
HDR_VERSION     equ     4
HDR_TYPE        equ     5
HDR_FLAGS       equ     6
HDR_RESERVED    equ     7
HDR_SEQ         equ     8
HDR_PLAYER_ID   equ     10
HDR_GAME_ID     equ     12
HDR_CHECKSUM    equ     14
PAYLOAD_START   equ     16
PAYLOAD_SIZE    equ     48

; Message types
MSG_JOIN        equ     $01
MSG_LEAVE       equ     $02
MSG_READY       equ     $03
MSG_GAME_START  equ     $10
MSG_GAME_STATE  equ     $11
MSG_GAME_END    equ     $12
MSG_PLAY_CARDS  equ     $20
MSG_DRAW_CARD   equ     $21
MSG_NOMINATE    equ     $22
MSG_ACK         equ     $F0
MSG_NAK         equ     $F1

; Connection states
CONN_DISCONNECTED equ   0
CONN_HANDSHAKE    equ   1
CONN_WAITING      equ   2
CONN_PLAYING      equ   3

; Card constants
SUIT_HEARTS     equ     0
SUIT_DIAMONDS   equ     1
SUIT_CLUBS      equ     2
SUIT_SPADES     equ     3

RANK_ACE        equ     1
RANK_JACK       equ     11
RANK_QUEEN      equ     12
RANK_KING       equ     13
