package hosynth

import "core:math"

Envelope :: struct { // all time-related values are in ms
    attack_time, decay_time, sustain_level, release_time: f32,
}

Unison_Voice :: struct {
    phase: f32,
}

Note_Osc :: struct {
    unison: [11]Unison_Voice,
}

Note :: struct {
    playing: bool,
    freq: f32,

    oscs: [3]Note_Osc,
    
    press_samples, release_samples: int,
    release_start_amp: f32,
}

Unison :: struct {
    voices: int,
    detune: f32,
}

Oscillator :: struct {
    base: Waveform,
    unison: Unison,
    octave: f32,
    semitone: f32,
    phase: f32,
    level: f32,
    muted: bool,
    env: Envelope,
}

Synth :: struct {
    oscs: [3]Oscillator,
    current_osc: ^Oscillator,
    current_osc_index: int,
    notes: [len(KEYBOARD)]Note,
    gain: f32,
}

default_osc :: proc() -> Oscillator {
    return Oscillator{
        base = .Sine,
        unison = {1, 10},
        octave = 0,
        semitone = 0,
        phase = 0,
        level = 1,
        muted = true,
        env = {20, 500, 0.70, 20},
    }
}

calc_note_amp :: proc(note: Note, env: Envelope) -> f32 {
    attack_samples := int(env.attack_time * SAMPLE_RATE / 1000)
    decay_samples := int(env.decay_time * SAMPLE_RATE / 1000)
    release_samples := int(env.release_time * SAMPLE_RATE / 1000)

    if note.playing {
        decay_cutoff := attack_samples + decay_samples
        if note.press_samples < attack_samples { // Attack section
            ratio := f32(note.press_samples) / f32(attack_samples)
            return ratio
        } else if note.press_samples < decay_cutoff { // Decay section
            // Lerp between attack level and sustain level
            ratio := f32(note.press_samples - attack_samples) / f32(decay_samples)
            return ratio * env.sustain_level + (1 - ratio)
        } else { // Sustain section
            return env.sustain_level
        }
    } else { // release
        if note.release_samples < release_samples {
            ratio := f32(note.release_samples) / f32(release_samples)
            return (1 - ratio) * note.release_start_amp
        } else {
            return f32(0.0)
        }
    }
}

get_freq :: proc(semitones: int) -> f32 {
    semitone_diff := math.pow(f32(2.0), 1.0 / 12.0)
    return C3 * math.pow(semitone_diff, f32(semitones))
}

detune_freq :: proc(freq, cents: f32) -> f32 {
    return freq * math.pow(2.0, cents / 1200.0)
}

set_note :: proc(note: ^Note, synth: ^Synth, buffer: ^[BUFFER_SIZE]f32) {
    for i in 0..<BUFFER_SIZE {
        for &osc, index in synth.oscs {
            amp := calc_note_amp(note^, osc.env)
            octave_mult := math.pow(2.0, osc.octave) * math.pow(2.0, osc.semitone / 12.0)
            voices := osc.unison.voices
            unison_gain := 1.0 / math.sqrt(f32(voices))
            if osc.muted {
                continue
            }

            for j in 0..<voices {
                offset := j - (voices - 1) / 2

                freq := detune_freq(note.freq, f32(offset) * osc.unison.detune)

                phase_inc := freq * octave_mult / f32(SAMPLE_RATE)

                sample := basic_waveform(osc.base, 2.0 * math.PI * note.oscs[index].unison[j].phase + osc.phase)

                buffer^[i] += sample * unison_gain * amp * osc.level

                note.oscs[index].unison[j].phase += phase_inc

                if note.oscs[index].unison[j].phase >= 1.0 {
                    note.oscs[index].unison[j].phase -= 1.0
                }
            }
        }

        if note.playing {
            note.press_samples += 1
        } else {
            note.release_samples += 1
        }
    }
}
