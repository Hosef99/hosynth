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
        env = e_piano,
        gain = 0.4,
    }

    for &osc in synth.oscs {
        osc = default_osc()
    }

    // Defaults to the 0th oscillator
    synth.current_osc = &synth.oscs[0]
    synth.current_osc_index = 0

    // Oscillator default setting
    synth.current_osc^ = Oscillator{
        base = .Triangle,
        unison = {
            voices = 3,
            detune = 10,
        },
        octave = 0,
        semitone = 0,
        level = 1,
        muted = false,
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

        synth.current_osc.unison.voices = int(slider_steps(unison_slider, []f32{1, 3, 5, 7, 9, 11}))
        // SNAPPING
        unison_slider.val = f32(synth.current_osc.unison.voices - 1) / 10.0
        synth.current_osc.unison.detune = slider_float(detune_slider, 0, 50)
        synth.current_osc.octave = f32(slider_int(octave_slider, -2, 2))
        octave_slider.val = (synth.current_osc.octave + 2) / 4.0
        synth.current_osc.semitone = slider_float(semitone_slider, -12, 12)
        synth.current_osc.phase = slider_float(phase_slider, 0, 360)
        // synth.current_osc.level = level_slider.val
        for &osc, index in synth.oscs {
            if osc_level_sliders[index].val == 0 {
                osc.level = 0
            } else {
                osc.level = db_to_ratio(slider_float(osc_level_sliders[index]^, -24, 3))
            }
        }

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
