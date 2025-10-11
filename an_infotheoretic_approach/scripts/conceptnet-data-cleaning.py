import pandas as pd
import re
import os
from pathlib import Path

# same helper functions as before
STOPTOK = {"n", "v", "a", "r", "adj", "adv", "pron", "wikt", "wikipedia"}

def clean_token(token):
    if pd.isna(token):
        return token
    s = str(token).strip().strip("[] ")
    parts = [p for p in s.split("/") if p]
    if not parts:
        return s

    candidate = None
    for i, p in enumerate(parts):
        if p == "en" and i + 1 < len(parts):
            for j in range(i + 1, len(parts)):
                if parts[j] not in STOPTOK and not re.match(r"^en_\d+$", parts[j]):
                    candidate = parts[j]
                    break
            if candidate is not None:
                break
    if candidate is None:
        for p in parts:
            if p not in STOPTOK and not re.match(r"^en_\d+$", p):
                candidate = p
                break
    if candidate is None:
        candidate = parts[-1]

    candidate = re.sub(r"^[^A-Za-z0-9._-]+|[^A-Za-z0-9._-]+$", "", candidate.strip())
    return candidate or parts[-1]

def extract_relation_from_url(url):
    if pd.isna(url):
        return ""
    s = str(url).strip().strip("[] ")
    return s.split("/")[0] if "/" in s else s.split()[0]

def preprocess_df(df):
    df = df.copy()
    df["start"] = df["start"].apply(clean_token)
    df["end"]   = df["end"].apply(clean_token)
    if "relation" not in df.columns:
        df["relation"] = df["URL"].apply(extract_relation_from_url)
    else:
        df["relation"] = df.apply(
            lambda r: r["relation"] if pd.notna(r["relation"]) and str(r["relation"]).strip() != "" 
                      else extract_relation_from_url(r.get("URL", "")),
            axis=1
        )
    df["URL"] = df.apply(lambda r: f"({r['relation']} {r['start']} {r['end']})", axis=1)
    rename_map = {}
    if "start" in df.columns:
        rename_map["start"] = "source"
    if "end" in df.columns:
        rename_map["end"] = "target"
    df = df.rename(columns=rename_map)

    return df

def preprocess_folder(input_folder, output_folder=None):
    input_folder = Path(input_folder)
    if output_folder:
        output_folder = Path(output_folder)
        output_folder.mkdir(parents=True, exist_ok=True)
    else:
        output_folder = input_folder

    for file in input_folder.glob("*.csv"):
        print(f"Processing {file.name}...")
        try:
            df = pd.read_csv(file, dtype=str, keep_default_na=False, na_values=[""])
            processed = preprocess_df(df)
            out_path = output_folder / file.name
            processed.to_csv(out_path, index=False)
            print(f" → Saved to {out_path}")
        except Exception as e:
            print(f" !! Failed to process {file.name}: {e}")

if __name__ == "__main__":
    preprocess_folder("/media/wendecoder/d41fa622-4710-466b-bfa5-5452a14bdc9e/home/wendecoder/Modifdied/", "/media/wendecoder/d41fa622-4710-466b-bfa5-5452a14bdc9e/home/wendecoder/output_csvs")
