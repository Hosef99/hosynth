# hosynth
Hosynth, a handwritten synth written in odin + raylib.

## Installing
Just clone it and run `odin run .` or `odin build .` to run/build it. You definitely need the odin compiler for this.

## Usage
Use your mouse to interact with the panel and tweak some values. Playable keys (2 octaves) are mapped to the following, with a separation of 1 semitone between consecutive keys:

First octave (excluding the upper C)
Q, 2, W, 3, E, R, 5, T, 6, Y, 7, U

Second octave (including the upper C)
Z, S, X, D, C, V, G, B, H, N, M, ','

So, to play a C major triad with root position, you can press the combination `[Q, E, T]` or `[Z, C, B]`

## Plan
Still very under development. But quite a lot has been achieved
- ~Add adjustment of ADSR in GUI~
- ~Add saw wave and square wave~
- LFOs?? (good luck buddy)
- ~Stacking multiple waves together~
- Solve delaying issues
