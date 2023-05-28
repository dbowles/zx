
  include "library/music.asm"

; Define the tune data
tuneData:
  defb noteC, durationWhole
  defb noteD, durationQuarter
  defb noteE, durationQuarter
  defb noteF, durationQuarter
  defb noteG, durationQuarter
  defb noteA, durationQuarter
  defb noteB, durationQuarter
  defb noteC*2, durationHalf
  defb noteB, durationQuarter
  defb noteA, durationQuarter
  defb noteG, durationQuarter
  defb noteF, durationQuarter
  defb noteE, durationQuarter
  defb noteD, durationQuarter
  defb noteC, durationHalf
  defb 0 ; End of tune marker
