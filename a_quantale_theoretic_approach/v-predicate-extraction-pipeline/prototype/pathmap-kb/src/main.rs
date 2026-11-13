use perspective_pathmap_prototype::{BuildStats, Index, ResultRow, stable_id};
use std::env;
use std::io;
use std::path::{Path, PathBuf};
use std::time::Instant;

fn usage() -> ! {
    eprintln!(
        "usage:\n  perspective-pathmap-prototype build --property-kb FILE --algebraic-kb FILE --out DIR [--limit-per-kind N]\n  perspective-pathmap-prototype benchmark --index DIR --perspective P --concept C [--iterations N] [--extensions N]\n  perspective-pathmap-prototype properties --index DIR --perspective P --concept C\n  perspective-pathmap-prototype worlds --index DIR --perspective P --concept C --property NAME\n  perspective-pathmap-prototype property-name --index DIR --perspective P --property NAME\n  perspective-pathmap-prototype algebra --index DIR --perspective P --concept C --family sort|operation|predicate|axiom"
    );
    std::process::exit(2)
}

fn option(args: &[String], name: &str) -> Option<String> {
    args.iter()
        .position(|a| a == name)
        .and_then(|i| args.get(i + 1))
        .cloned()
}

fn required(args: &[String], name: &str) -> String {
    option(args, name).unwrap_or_else(|| usage())
}

fn print_rows(rows: Vec<ResultRow>) {
    for row in rows {
        println!(
            "concept={}\tfamily={}\tfeature={}\tworld={}\tstrength={:.3}\tconfidence={:.3}\tpayload={}\tevidence={}",
            row.concept,
            row.family,
            row.feature,
            row.world.as_deref().unwrap_or("-"),
            row.strength,
            row.confidence,
            row.payload.as_deref().unwrap_or("-"),
            row.evidence
        );
        if let (Some(strength), Some(confidence)) = (row.payload_strength, row.payload_confidence) {
            println!(
                "  payload-tv=({strength:.3}, {confidence:.3})\tpayload-evidence={}",
                row.payload_evidence.as_deref().unwrap_or("-")
            );
        }
    }
}

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();
    let Some(command) = args.get(1).map(String::as_str) else {
        usage()
    };
    if command == "build" {
        let mut index = Index::default();
        let mut stats = BuildStats::default();
        let limit =
            option(&args, "--limit-per-kind").map(|v| v.parse::<u64>().unwrap_or_else(|_| usage()));
        index.ingest_file(
            Path::new(&required(&args, "--property-kb")),
            true,
            limit,
            &mut stats,
        )?;
        index.ingest_file(
            Path::new(&required(&args, "--algebraic-kb")),
            false,
            limit,
            &mut stats,
        )?;
        let out = PathBuf::from(required(&args, "--out"));
        index.save(&out, stats)?;
        eprintln!(
            "built {} perspective shards at {}: {:?}",
            index.shards.len(),
            out.display(),
            stats
        );
        return Ok(());
    }

    let root = PathBuf::from(required(&args, "--index"));
    let perspective = required(&args, "--perspective");
    let load_start = Instant::now();
    let mut index = Index::load_shard(&root, &perspective)?;
    let load_time = load_start.elapsed();
    if command == "benchmark" {
        let concept = required(&args, "--concept");
        let iterations = option(&args, "--iterations")
            .map(|value| value.parse::<u64>().unwrap_or_else(|_| usage()))
            .unwrap_or(20);
        let extensions = option(&args, "--extensions")
            .map(|value| value.parse::<u64>().unwrap_or_else(|_| usage()))
            .unwrap_or(10_000);
        if iterations == 0 {
            usage();
        }
        let warm_rows = index.build_specification(&perspective, &concept);
        let row_count = warm_rows.len();
        let query_start = Instant::now();
        let mut checksum = 0u64;
        for _ in 0..iterations {
            let rows = index.build_specification(&perspective, &concept);
            assert_eq!(rows.len(), row_count, "unstable specification result count");
            for row in rows {
                checksum = checksum.wrapping_add(
                    stable_id(&row.feature).rotate_left((row.family.len() % 64) as u32),
                );
                if let Some(world) = row.world {
                    checksum = checksum.wrapping_add(stable_id(&world));
                }
            }
        }
        let query_time = query_start.elapsed();
        let extension_start = Instant::now();
        index.extend_with_sorts("functional_use", "extension_concept", extensions)?;
        let extension_time = extension_start.elapsed();
        let extension_query_start = Instant::now();
        let visible_extensions = index
            .query_algebra("functional_use", "extension_concept", "sort")
            .len();
        let extension_query_time = extension_query_start.elapsed();
        assert_eq!(visible_extensions as u64, extensions);
        println!(
            "backend=pathmap load_ms={:.3} rows={} iterations={} query_total_ms={:.3} query_mean_us={:.3} checksum={} extension_count={} extension_ms={:.3} extension_query_us={:.3}",
            load_time.as_secs_f64() * 1000.0,
            row_count,
            iterations,
            query_time.as_secs_f64() * 1000.0,
            query_time.as_secs_f64() * 1_000_000.0 / iterations as f64,
            checksum,
            extensions,
            extension_time.as_secs_f64() * 1000.0,
            extension_query_time.as_secs_f64() * 1_000_000.0,
        );
        return Ok(());
    }
    let index = index;
    let rows = match command {
        "properties" => index.query_properties(&perspective, &required(&args, "--concept")),
        "worlds" => index.query_worlds(
            &perspective,
            &required(&args, "--concept"),
            &required(&args, "--property"),
        ),
        "property-name" => index.query_property_name(&perspective, &required(&args, "--property")),
        "algebra" => index.query_algebra(
            &perspective,
            &required(&args, "--concept"),
            &required(&args, "--family"),
        ),
        _ => usage(),
    };
    print_rows(rows);
    Ok(())
}
