package hosynth

import rl "vendor:raylib"
import "core:math"

SAMPLE_RATE :: 44100
BUFFER_SIZE :: 1024

A4 :: 440.0

get_freq :: proc(semitones: int) -> f32 {
    semitone_diff := math.pow(f32(2.0), 1.0 / 12.0)
    return A4 * math.pow(semitone_diff, f32(semitones))
}

main :: proc() {
    rl.InitWindow(800, 600, "Hosynth")

    defer rl.CloseWindow()

    rl.InitAudioDevice()

    defer rl.CloseAudioDevice()

    rl.SetAudioStreamBufferSizeDefault(BUFFER_SIZE)

    buffer: [BUFFER_SIZE]f32

    stream := rl.LoadAudioStream(SAMPLE_RATE, 32, 1)

    defer rl.UnloadAudioStream(stream)

    rl.PlayAudioStream(stream)

    freq: f32 = 440.0
    index := 0

    rl.SetTargetFPS(60)
    for !rl.WindowShouldClose() {
        if rl.IsKeyPressed(.UP) {
            freq *= math.pow(f32(2.0), 1.0/12.0)
        }
        else if rl.IsKeyPressed(.DOWN) {
            freq /= math.pow(f32(2.0), 1.0/12.0)
        }
        if rl.IsAudioStreamProcessed(stream) {
            for i in 0..<BUFFER_SIZE {
                wavelength: int = SAMPLE_RATE/int(freq)
                buffer[i] = math.sin(2.0*math.PI*f32(index)/f32(wavelength))
                index += 1

                if index >= wavelength {
                    index = 0
                }
            }
            rl.UpdateAudioStream(stream, &buffer[0], BUFFER_SIZE)
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.GetColor(0x181818FF))
        rl.EndDrawing()
    }
}
