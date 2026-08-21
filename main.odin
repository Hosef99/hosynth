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

sin_rect := rl.Rectangle{10, 115, 50, 30}
square_rect := rl.Rectangle{10+50, 115, 50, 30}
triangle_rect := rl.Rectangle{10+100, 115, 50, 30}
saw_rect := rl.Rectangle{10+150, 115, 50, 30}

basic_wave_rects := [4]rl.Rectangle{sin_rect, square_rect, triangle_rect, saw_rect}

main :: proc() {
    e_piano := Envelope{20, 500, 0.70, 20}
    synth := Synth{
        wave = {.Triangle, 0, {3, 30}},
        env = e_piano,
        gain = 0.4,
    }

    for &note, i in synth.notes {
        note.freq = get_freq(i)
        note.unison = make([]Unison_Voice, 5)
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
