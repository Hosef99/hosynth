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
        wave = {2, 0, {3, 10}},
        env = e_piano,
        gain = 0.2,
    }

    for &note, i in synth.notes {
        note.freq = get_freq(i)
        note.unison = make([]Unison_Voice, 3)
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

        for &note, i in synth.notes {
            if rl.IsKeyPressed(keyboard[i]) {
                note.playing = true
                note.release_samples = 0
            } else if rl.IsKeyReleased(keyboard[i]) {
                note.release_start_amp = calc_note_amp(note, synth.env)
                note.playing = false
                note.press_samples = 0
            }
        }

        if rl.IsAudioStreamProcessed(audio.stream) {
            process_audio(audio, &synth)
        }

        // Drawing
        rl.BeginDrawing()
        rl.ClearBackground(rl.GetColor(0x181818FF))

        // draw wave shape
        rl.DrawRectangleLines(10, 10, 200, 100, {255, 255, 255, 255})

        SEGMENT_SIZE :: 300
        display_lines: [SEGMENT_SIZE][2]f32
        for i in 0..<SEGMENT_SIZE {
            angle := f32(i)/f32(SEGMENT_SIZE)*4.0*math.PI
            value := waveform(synth.wave, angle)
            display_lines[i] = {15.0 + f32(i)/f32(SEGMENT_SIZE) * 190.0, 10.0 + 50.0 - value * 45.0}
        }
        rl.DrawLineStrip(raw_data(display_lines[:]), len(display_lines), {255, 0, 0, 255})

        rl.DrawRectangleLines(5, 5, 210, HEIGHT-10, {255, 255, 255, 255})

        // Handle event
        for wave in 0..<len(basic_wave_rects) {
            if rl.CheckCollisionPointRec(mouse_pos, basic_wave_rects[wave]) && rl.IsMouseButtonPressed(.LEFT) {
                synth.wave.base = wave
            }
        }
        
        // Draw Waveform UIs
        SEGMENT :: 50
        waveform_lines: [SEGMENT][2]f32
        for wave in 0..<len(basic_waves) {
            for i in 0..<SEGMENT {
                angle := f32(i)/f32(SEGMENT)*2.0*math.PI
                value := basic_waves[wave](angle)
                waveform_lines[i] = {10.0 + 50.0 * f32(wave) + f32(i)/f32(SEGMENT) * 50.0, 115.0 + 15.0 - value * 10.0}
            }

            selected := synth.wave.base == wave

            color := rl.RED if selected else rl.WHITE
            border := rl.GREEN if selected else rl.WHITE

            rl.DrawLineStrip(raw_data(waveform_lines[:]), len(waveform_lines), color)
            rl.DrawRectangleLinesEx(basic_wave_rects[wave], 1.0, border)
        }

        rl.EndDrawing()
    }
}
