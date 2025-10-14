// rust/etl.rs
use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::{Command, Stdio};

#[derive(Debug)]
struct Args {
    db: PathBuf,
    table: String,
    csv: PathBuf,
}

fn parse_args() -> Args {
    let mut db = PathBuf::from("world_data.db");
    let mut table = String::from("countries");
    let mut csv = PathBuf::from("countries.csv");

    let mut it = env::args().skip(1);
    while let Some(flag) = it.next() {
        match flag.as_str() {
            "--db" => db = PathBuf::from(it.next().expect("--db needs a value")),
            "--table" => table = it.next().expect("--table needs a value"),
            "--csv" => csv = PathBuf::from(it.next().expect("--csv needs a value")),
            other => {
                eprintln!("Unknown arg: {other}");
                std::process::exit(2);
            }
        }
    }
    Args { db, table, csv }
}

fn run(cmd: &mut Command) {
    let display = format!("{:?}", cmd);
    let status = cmd.status().expect("failed to start process");
    if !status.success() {
        eprintln!("Command failed: {}", display);
        std::process::exit(status.code().unwrap_or(1));
    }
}

fn run_capture(cmd: &mut Command) -> String {
    let display = format!("{:?}", cmd);
    let out = cmd.stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .output()
        .expect("failed to run process");
    if !out.status.success() {
        eprintln!("Command failed: {}", display);
        eprintln!("{}", String::from_utf8_lossy(&out.stderr));
        std::process::exit(out.status.code().unwrap_or(1));
    }
    String::from_utf8_lossy(&out.stdout).to_string()
}

fn main() {
    let args = parse_args();
    println!("ETL start → DB: {:?}, table: {}, csv: {:?}", args.db, args.table, args.csv);

    // Extract. Fetch JSON to a temp file (or repo-local file)
    let json_path = PathBuf::from("countries.tmp.json");
    println!("Fetching REST Countries JSON …");
    run(
        Command::new("curl")
            .arg("-L")
            .arg("-sS")
            .arg("-H").arg("Accept: application/json")
            .arg("https://restcountries.com/v3.1/all?fields=name,region,population,area")
            .arg("-o")
            .arg(&json_path)
    );

    // Transform. JSON -> CSV - jq
    println!("Transforming JSON -> CSV …");
    let jq_prog = r#"
      def root:
        if type == "string" then
          (try fromjson catch .)
        else
          .
        end;

      def rows($r):
        if ($r | type) == "array" then $r[]
        elif ($r | type) == "object" and ($r | has("data")) then $r.data[]
        else empty
        end;

      (["country","region","population","area","density"]),
      ( root as $r
        | rows($r)
        | {
            country: (.name.common // "Unknown"),
            region:  (.region // "Unknown"),
            population: (.population),
            area: (.area),
            density: (if (.population and .area and (.area > 0))
                  then (.population / .area)
                  else null end)
          }
        | [ .country, .region, .population, .area, .density ])
      | @csv
    "#;

    let csv_str = run_capture(
        Command::new("jq")
            .arg("-r")
            .arg(jq_prog)
            .arg(&json_path)
    );
    fs::write(&args.csv, csv_str).expect("failed to write CSV");

    // Load. Generate table & import CSV into SQLite
    println!("Loading into SQLite …");
    let create_sql = format!(
        r#"
        CREATE TABLE IF NOT EXISTS {tbl} (
            country    TEXT NOT NULL,
            region     TEXT NOT NULL,
            population INTEGER,
            area       REAL,
            density    REAL
        );
        DELETE FROM {tbl};
        "#,
        tbl = &args.table
    );

    // Run schema DDL
    run(
        Command::new("sqlite3")
            .arg(&args.db)
            .arg(&create_sql)
    );

    run(
        Command::new("sqlite3")
            .arg(&args.db)
            .arg("-cmd").arg(".mode csv")
            .arg("-cmd").arg(format!(".import --skip 1 {} {}", args.csv.display(), args.table))
            .arg(".quit")
    );

    // Validate region counts
    println!("Validation (region counts):");
    let out = run_capture(
        Command::new("sqlite3")
            .arg(&args.db)
            .arg(format!(
                "SELECT region, COUNT(*) AS cnt FROM {} GROUP BY region ORDER BY cnt DESC;",
                args.table
            ))
    );
    println!("{out}");

    // Cleanup temp JSON
    let _ = fs::remove_file(&json_path);

    println!("ETL done ✅\n- DB:   {}\n- CSV:  {}\n- Table: {}",
        args.db.display(), args.csv.display(), args.table);
}
