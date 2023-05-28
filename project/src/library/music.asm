; *********************************************************************************************************************
; Author:  Darren Bowles
; Date:    2020-05-03
; Purpose: Simple music
; *********************************************************************************************************************

; Define the note frequencies
noteC: equ 0x30
noteD: equ 0x34
noteE: equ 0x38
noteF: equ 0x3C
noteG: equ 0x40
noteA: equ 0x44
noteB: equ 0x48

; Define the note durations
durationWhole: equ 32
durationHalf: equ 16
durationQuarter: equ 8
durationEighth: equ 4


loadNote:
  
  ; increment the in game music note index
  ld a, (currentNote)
  inc a
  ld (currentNote), a
  

  ; this is like multiply by 128
  and 126
  rrca

  ld e, a
  ld d, 0

  ld hl, tune
  add hl, de

  ld a,7 ; pitch
  rlca ; multiply by 2
  rlca ; multiply by 4

  sub 28 
  neg ; make it positive

  add a, (hl) ; add the entry from the tune data for the current note
  ld d,a ; store the pitch in d

  ld a,0 ; border colour

  ld e, d ; initialise the pitch delay counter
  ld bc, 3 ; initialise the duration delay counters in b (0) and c(3)
.noise:
  out (254), a ; make a noise
  dec e
  jr nz, .here
  ld e,d
  xor 24
.here:
  djnz .noise
  dec c
  jr nz, .noise

  
  ret


noteDuration:
  dw 0 ; Variable to store the remaining duration of the current note  
currentNote:
  db 0 ; Variable to store the current note being played


; Constants for musical notes
Pause     equ 0       ; Pause or rest
C4 EQU 64
CSharp4 EQU 68
D4 EQU 72
DSharp4 EQU 76
E4 EQU 81
F4 EQU 86
FSharp4 EQU 91
G4 EQU 96
GSharp4 EQU 102
A4 EQU 108
ASharp4 EQU 114
B4 EQU 120
C5 EQU 128
CSharp5 EQU 136
D5 EQU 144
DSharp5 EQU 152
E5 EQU 161
F5 EQU 170
FSharp5 EQU 180
G5 EQU 192
GSharp5 EQU 204
A5 EQU 216
ASharp5 EQU 229
B5 EQU 242
C6 EQU 255




; Melody data

tune:
  db 128, 102, 86, 86, 171, 43
  db 43
  db 171
  db 51
  db 51
  db 171
  db 128
  db 128
  db 102
  db 86
  db 96
  db 171
  db 43
  db 43
  db 171
  db 48
  db 48
  db 171
  db 136
  db 136
  db 114
  db 76
  db 76
  db 171
  db 38
  db 38
  db 171
  db 48
  db 48
  db 171
  db 136
  db 136
  db 114
  db 76
  db 76
  db 171
  db 38
  db 38
  db 171
  db 51
  db 51
  db 171
  db 128
  db 128
  db 102
  db 86
  db 64
  db 128
  db 32
  db 32
  db 128
  db 43
  db 43
  db 128
  db 128
  db 128
  db 102
  db 86
  db 64
  db 128
  db 32
  db 32
  db 128
  db 38
  db 38
  db 0
  db 114
  db 114
  db 96
  db 76
  db 76
  db 76
  db 76
  db 76
  db 91
  db 86
  db 51
  db 51
  db 51
  db 51
  db 64
  db 102
  db 102
  db 114
  db 76
  db 86
  db 128
  db 128
  db 128
  db 128

  ; in the hall of the mountain king
  ; db C5,ASharp4,GSharp4,G4,F4,GSharp4,F4,F4,E4,G4,E4,E4,F4,GSharp4,F4,F4        
  ; db C5,ASharp4,GSharp4,G4,F4,GSharp4,F4,F4,E4,G4,E4,E4,F4,F4,F4,F4     
  ; db C5,ASharp4,GSharp4,G4,F4,GSharp4,F4,F4,E4,G4,E4,E4,F4,GSharp4,F4,F4        
  ; db C5,ASharp4,GSharp4,G4,F4,GSharp4,F4,C4,F4,GSharp4,C5,GSharp4,F4,F4,F4,F4  

  ; if I were a rich man
  ; db F4,G4,F4,G4,GSharp4,GSharp4,C5,C5,C5,C5,GSharp4,G4,F4,G4,F4,G4     
  ; db GSharp4,G4,F4,DSharp4,D4,DSharp4,D4,DSharp4,F4,F4,F4,F4,F4,F4,F4,F4        
  ; db C4,C4,C4,C4,CSharp4,CSharp4,DSharp4,DSharp4,F4,G4,GSharp4,G4,F4,F4,GSharp4,GSharp4 
  ; db E4,F4,G4,F4,E4,E4,G4,G4,C4,C4,C4,C4,C4,C4,C4,C4   