# /// script
# requires-python = ">=3.12,<3.13"
# dependencies = [
#     "mlx-whisper",
#     "numpy",
# ]
# ///
"""ASR round-trip verification for generated speech: no listening required.

Transcribes the WAV with Whisper (MLX) and checks, against the generation
report produced by kyutai_tts.py:
  1. word error rate after aggressive text normalization on both sides,
  2. degeneration loops (n-grams repeated many times in a row),
  3. coverage (transcript length vs. reference length),
  4. dead air (long inter-segment silences),
  5. per-chunk speech-rate outliers from the generation report.

Exit code 0 means every check passed.
"""

import argparse
import json
import re
import sys

import numpy as np

# --- number expansion: keep behavior identical to kyutai_tts.py ------------

ONES = [
    "zero", "one", "two", "three", "four", "five", "six", "seven", "eight",
    "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
    "sixteen", "seventeen", "eighteen", "nineteen",
]
TENS = [
    "", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
    "eighty", "ninety",
]
SCALES = [(10**9, "billion"), (10**6, "million"), (10**3, "thousand")]

ORDINAL_ONES = {
    "one": "first", "two": "second", "three": "third", "five": "fifth",
    "eight": "eighth", "nine": "ninth", "twelve": "twelfth",
}


def int_to_words(n: int) -> str:
    if n < 0:
        return "minus " + int_to_words(-n)
    if n < 20:
        return ONES[n]
    if n < 100:
        tens, rem = divmod(n, 10)
        return TENS[tens] + (" " + ONES[rem] if rem else "")
    if n < 1000:
        hundreds, rem = divmod(n, 100)
        out = ONES[hundreds] + " hundred"
        return out + (" " + int_to_words(rem) if rem else "")
    for scale, name in SCALES:
        if n >= scale:
            major, rem = divmod(n, scale)
            out = int_to_words(major) + " " + name
            return out + (" " + int_to_words(rem) if rem else "")
    return str(n)


def ordinal_to_words(n: int) -> str:
    words = int_to_words(n)
    head, _, last = words.rpartition(" ")
    if last in ORDINAL_ONES:
        last = ORDINAL_ONES[last]
    elif last.endswith("y"):
        last = last[:-1] + "ieth"
    else:
        last = last + "th"
    return (head + " " + last).strip()


def digits_to_words(digits: str) -> str:
    return " ".join(ONES[int(d)] for d in digits)


def number_to_words(num: str) -> str:
    num = num.replace(",", "")
    if "." in num:
        whole, frac = num.split(".", 1)
        out = int_to_words(int(whole)) if whole else "zero"
        if frac:
            out += " point " + digits_to_words(frac)
        return out
    return int_to_words(int(num))


NUM = r"\d+(?:,\d{3})*(?:\.\d+)?"


def expand_numbers(text: str) -> str:
    text = re.sub(r"(?<=[A-Za-z])(?=\d)", " ", text)
    text = re.sub(
        r"(?<![\d.])(\d+(?:\.\d+){2,})(?![\d.])",
        lambda m: " point ".join(number_to_words(p) for p in m.group(1).split(".")),
        text,
    )
    text = re.sub(
        rf"\$({NUM})\s+(thousand|million|billion|trillion)\b",
        lambda m: f"{number_to_words(m.group(1))} {m.group(2)} dollars",
        text,
    )

    def _currency(m: re.Match) -> str:
        amount = number_to_words(m.group(1))
        unit = "dollar" if m.group(1).replace(",", "") in ("1", "1.0") else "dollars"
        suffix = (m.group(2) or "").lower()
        if suffix:
            scale = {"k": "thousand", "m": "million", "b": "billion"}.get(suffix, suffix)
            return f"{amount} {scale} dollars"
        return f"{amount} {unit}"

    text = re.sub(rf"\$({NUM})([kKmMbB])?\b", _currency, text)
    text = re.sub(rf"({NUM})\s*%", lambda m: number_to_words(m.group(1)) + " percent", text)

    def _time_of_day(m: re.Match) -> str:
        hours, minutes = int(m.group(1)), m.group(2)
        out = int_to_words(hours)
        if minutes == "00":
            return out + " o'clock"
        if minutes.startswith("0"):
            return out + " oh " + int_to_words(int(minutes))
        return out + " " + int_to_words(int(minutes))

    text = re.sub(r"\b(\d{1,2}):([0-5]\d)\b", _time_of_day, text)
    text = re.sub(r"\b(\d+)(st|nd|rd|th)\b", lambda m: ordinal_to_words(int(m.group(1))), text)
    def _decade(m: re.Match) -> str:
        words = int_to_words(int(m.group(1)[:2])) + " " + int_to_words(int(m.group(1)[2:]))
        return words[:-1] + "ies" if words.endswith("y") else words + "s"

    text = re.sub(r"\b(\d{4})s\b", _decade, text)
    text = re.sub(r"(?<=[A-Za-z])(?=\d)|(?<=\d)(?=[A-Za-z])", " ", text)
    text = re.sub(
        r"\b(\d+)\s*-\s*(\d+)\b",
        lambda m: int_to_words(int(m.group(1))) + " to " + int_to_words(int(m.group(2))),
        text,
    )

    def _plain(m: re.Match) -> str:
        raw = m.group(0)
        bare = raw.replace(",", "")
        if "," not in raw and "." not in raw and len(bare) == 4 and bare.isdigit():
            year = int(bare)
            if 1900 <= year <= 2099:
                if bare == "2000":
                    return "two thousand"
                if bare[2:] == "00":
                    return int_to_words(int(bare[:2])) + " hundred"
                return int_to_words(int(bare[:2])) + " " + (
                    "oh " + ONES[int(bare[3])] if bare[2] == "0" else int_to_words(int(bare[2:]))
                )
        return number_to_words(raw)

    text = re.sub(NUM, _plain, text)
    return text


# --- normalization for WER --------------------------------------------------

FILLERS = {"uh", "um", "mm", "hmm", "mhm", "ah", "oh", "eh"}


def normalize_for_wer(text: str) -> list[str]:
    text = text.lower()
    text = text.replace("\u2019", "'")
    text = expand_numbers(text)
    text = text.replace("&", " and ")
    text = re.sub(r"[^a-z'\s]", " ", text)
    text = re.sub(r"'\s", " ", text)
    words = text.split()
    # Collapse single-letter runs (acronyms): c x d -> cxd.
    out: list[str] = []
    run: list[str] = []
    for word in words:
        if len(word) == 1 and word.isalpha() and word not in ("a", "i"):
            run.append(word)
            continue
        if run:
            out.append("".join(run))
            run = []
        if word in FILLERS:
            continue
        out.append(word)
    if run:
        out.append("".join(run))
    return out


def word_error_rate(ref: list[str], hyp: list[str]) -> float:
    if not ref:
        return 0.0 if not hyp else 1.0
    previous = np.arange(len(hyp) + 1, dtype=np.int32)
    hyp_arr = np.array(hyp)
    for i, ref_word in enumerate(ref, 1):
        current = np.empty_like(previous)
        current[0] = i
        substitution = previous[:-1] + (hyp_arr != ref_word)
        deletion = previous[1:] + 1
        np.minimum(substitution, deletion, out=substitution)
        # insertion needs a scan; do it with a running minimum.
        running = current[0]
        for j in range(1, len(previous)):
            running = min(substitution[j - 1], running + 1)
            current[j] = running
        previous = current
    return float(previous[-1]) / len(ref)


def find_loops(words: list[str], n: int = 3, min_repeats: int = 4) -> list[str]:
    loops = []
    i = 0
    while i + n <= len(words):
        gram = words[i : i + n]
        repeats = 1
        j = i + n
        while j + n <= len(words) and words[j : j + n] == gram:
            repeats += 1
            j += n
        if repeats >= min_repeats:
            loops.append(f"'{' '.join(gram)}' x{repeats} at word {i}")
            i = j
        else:
            i += 1
    return loops


def diff_regions(ref: list[str], hyp: list[str], limit: int = 12) -> list[str]:
    import difflib

    matcher = difflib.SequenceMatcher(a=ref, b=hyp, autojunk=False)
    regions = []
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == "equal":
            continue
        size = max(i2 - i1, j2 - j1)
        regions.append((size, f"[{tag}] ref[{i1}:{i2}] {' '.join(ref[i1:i2])[:90]!r} -> hyp {' '.join(hyp[j1:j2])[:90]!r}"))
    regions.sort(key=lambda r: -r[0])
    return [r[1] for r in regions[:limit]]


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify TTS output via ASR round-trip")
    parser.add_argument("wav")
    parser.add_argument("report", help="JSON report from kyutai_tts.py")
    parser.add_argument("--asr-model", default="mlx-community/whisper-large-v3-turbo")
    parser.add_argument("--max-wer", type=float, default=0.08)
    parser.add_argument("--min-coverage", type=float, default=0.9)
    parser.add_argument("--max-coverage", type=float, default=1.1)
    parser.add_argument("--max-silence", type=float, default=3.0)
    parser.add_argument("--json-out", help="write verification details here")
    args = parser.parse_args()

    with open(args.report, "r", encoding="utf-8") as fobj:
        report = json.load(fobj)

    import mlx_whisper

    print("transcribing...", file=sys.stderr)
    result = mlx_whisper.transcribe(
        args.wav,
        path_or_hf_repo=args.asr_model,
        language="en",
        temperature=0.0,
        condition_on_previous_text=False,
        no_speech_threshold=0.4,
    )
    transcript = result["text"]
    segments = result.get("segments", [])

    ref = normalize_for_wer(report["normalized_text"])
    hyp = normalize_for_wer(transcript)

    wer = word_error_rate(ref, hyp)
    coverage = len(hyp) / max(1, len(ref))
    loops = find_loops(hyp)

    silences = []
    last_end = 0.0
    for segment in segments:
        gap = segment["start"] - last_end
        if gap > args.max_silence:
            silences.append(f"{gap:.1f}s silent before {segment['start']:.1f}s")
        last_end = segment["end"]

    rate_outliers = [
        f"chunk {c['index']}: {c['wps']:.2f} wps ({c['words']} words, {c['seconds']:.1f}s)"
        for c in report.get("chunks", [])
        if c["words"] >= 6 and not (1.2 <= c["wps"] <= 4.5)
    ]

    failures = []
    if wer > args.max_wer:
        failures.append(f"WER {wer:.3f} > {args.max_wer}")
    if not (args.min_coverage <= coverage <= args.max_coverage):
        failures.append(f"coverage {coverage:.3f} outside [{args.min_coverage}, {args.max_coverage}]")
    if loops:
        failures.append(f"{len(loops)} degeneration loop(s): {loops[:3]}")
    if silences:
        failures.append(f"{len(silences)} long silence(s): {silences[:3]}")

    print(f"ref words:  {len(ref)}")
    print(f"hyp words:  {len(hyp)}")
    print(f"WER:        {wer:.3f}")
    print(f"coverage:   {coverage:.3f}")
    print(f"loops:      {len(loops)}")
    print(f"silences:   {len(silences)}")
    if rate_outliers:
        print(f"rate outliers (report): {rate_outliers[:5]}")
    print("--- largest diff regions ---")
    for region in diff_regions(ref, hyp):
        print(" ", region)

    if args.json_out:
        with open(args.json_out, "w", encoding="utf-8") as fobj:
            json.dump(
                {
                    "wer": wer,
                    "coverage": coverage,
                    "loops": loops,
                    "silences": silences,
                    "rate_outliers": rate_outliers,
                    "failures": failures,
                    "transcript": transcript,
                },
                fobj,
                indent=1,
            )

    if failures:
        print("FAIL: " + "; ".join(failures))
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
