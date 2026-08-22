package hosynth

import "core:fmt"
import rl "vendor:raylib"
import "core:math"

WIDTH :: 900
HEIGHT :: 600

SAMPLE_RATE :: 48000
BUFFER_SIZE :: 2048

C3 :: 130.8

KEYBOARD :: [?]rl.KeyboardKey{.Q, .TWO, .W, .THREE, .E, .R, .FIVE, .T, .SIX, .Y, .SEVEN, .U, .Z, .S, .X, .D, .C, .V, .G, .B, .H, .N, .J, .M, .COMMA}

main :: proc() {
    e_piano := Envelope{20, 500, 0.70, 20}
    synth := Synth{
        wave = {.Triangle, {3, 10}, 0, 0},
        env = e_piano,
        gain = 0.4,
    }

    for &note, i in synth.notes {
        note.freq = get_freq(i)
    }
    keyboard := KEYBOARD

    rl.InitWindow(WIDTH, HEIGHT, "Hosynth")

    defer rl.CloseWindow()

    rl.InitAudioDevice()

    defer rl.CloseAudioDevice()

    rl.SetAudioStreamBufferSizeDefault(BUFFER_SIZE)

    stream := rl.LoadAudioStream(SAMPLE_RATE, 32, 1)
    audio := Audio{stream}

    defer rl.UnloadAudioStream(stream)

    rl.PlayAudioStream(stream)

    rl.SetTargetFPS(60)
    for !rl.WindowShouldClose() {
        mouse_pos := rl.GetMousePosition()

        handle_input(&synth)

        synth.wave.unison.voices = int(slider_steps(unison_slider, []f32{1, 3, 5, 7, 9, 11}))
        // SNAPPING
        unison_slider.val = f32(synth.wave.unison.voices - 1) / 10.0
        synth.wave.unison.detune = slider_float(detune_slider, 0, 50)
        synth.wave.octave = slider_float(octave_slider, -3, 3)
        synth.wave.semitone = slider_float(semitone_slider, -12, 12)

        if rl.IsAudioStreamProcessed(audio.stream) {
            process_audio(audio, &synth)
        }

        handle_ui_input(&synth, mouse_pos)

        // Drawing
        rl.BeginDrawing()
        draw_ui(synth)
        rl.EndDrawing()
    }
}
