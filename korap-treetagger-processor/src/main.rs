use clap::{Parser, Subcommand};
use std::io::{self, BufRead, Write};

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Preprocess,
    Postprocess,
    FilterGerman,
}

fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Preprocess => preprocess(),
        Commands::Postprocess => postprocess(),
        Commands::FilterGerman => filter_german(),
    }
}

fn preprocess() -> anyhow::Result<()> {
    let stdin = io::stdin();
    let mut stdout = io::stdout();
    let mut handle = stdin.lock();
    let mut buffer = String::new();

    while handle.read_line(&mut buffer)? > 0 {
        let mut line = buffer.as_str();
        
        // $_=substr($_, 0, 99000);
        if line.len() > 99000 {
            line = &line[..99000];
        }
        
        let trimmed = line.trim_end(); // Handle potential newline issues if we sliced it off? 
        // Actually perl substr keeps the newline if it's within the limit, or cuts it off.
        // But the regexes work on the string.
        
        // s/^(#.*|$)/<$1>/
        // Note: $ matches end of string (newline in Perl usually, but here we have line content)
        // If line is empty (just newline), it matches ^$
        
        // We need to be careful with newlines. `read_line` includes the newline.
        // Perl `perl -wlnpe` : -l handles line endings automatically (chomps input, adds to output).
        // Wait, `perl -wlnpe`
        // -n: loop around input
        // -p: print $_ at end of loop
        // -l: chomp input, append $\ (newline) to output.
        
        // So $_ does NOT have newline when processing.
        
        let mut content = line.trim_end().to_string();
        
        // $_=substr($_, 0, 99000);
        if content.len() > 99000 {
            content.truncate(99000);
        }

        // s/^(#.*|$)/<$1>/
        if content.starts_with('#') || content.is_empty() {
            content = format!("<{}>", content);
        } 
        // s/^[\d.]+\t([^\t]*).*/$1/
        else if let Some(idx) = content.find('\t') {
             // Check if start is digits/dots
             let prefix = &content[..idx];
             if prefix.chars().all(|c| c.is_ascii_digit() || c == '.') {
                 // Extract second column
                 let rest = &content[idx+1..];
                 if let Some(end_idx) = rest.find('\t') {
                     content = rest[..end_idx].to_string();
                 } else {
                     content = rest.to_string();
                 }
             }
        }

        writeln!(stdout, "{}", content)?;
        buffer.clear();
    }
    Ok(())
}

fn postprocess() -> anyhow::Result<()> {
    let stdin = io::stdin();
    let mut stdout = io::stdout();
    let mut handle = stdin.lock();
    let mut buffer = String::new();
    
    let mut id = 0;

    while handle.read_line(&mut buffer)? > 0 {
        let mut line = buffer.trim_end().to_string();
        
        // s/^<(.*)>$/$1/
        if line.starts_with('<') && line.ends_with('>') {
            line = line[1..line.len()-1].to_string();
        }

        // s/^(# *foundry *= *)base/$1 tree_tagger/
        if line.starts_with("#") && line.contains("foundry") && line.contains("base") {
             // Simple replacement for now, regex if needed
             // Perl: s/^(# *foundry *= *)base/$1 tree_tagger/
             // This keeps the prefix and changes base to tree_tagger
             // We can use regex for this to be safe
             let re = regex::Regex::new(r"^(# *foundry *= *)base").unwrap();
             line = re.replace(&line, "${1}tree_tagger").to_string();
        }

        // $id++; $id=0 if(/^(#|\s*$)/);
        id += 1;
        if line.starts_with('#') || line.trim().is_empty() {
            id = 0;
        }

        // my @cols = split("\t");
        let cols: Vec<&str> = line.split('\t').collect();

        if cols.len() == 3 {
             // print "$id\t$cols[0]\t$cols[2]\t_\t$cols[1]\t_\t_\t_\t_\t_"
             writeln!(stdout, "{}\t{}\t{}\t_\t{}\t_\t_\t_\t_\t_", id, cols[0], cols[2], cols[1])?;
        } else if cols.len() > 3 {
            // my $extra = join(" ", @cols[3..$#cols]);
            let extra_parts = &cols[3..];
            let mut extra = extra_parts.join(" ");
            
            // $extra =~ s/^[fsc]\s+//;
            if extra.starts_with("f ") || extra.starts_with("s ") || extra.starts_with("c ") {
                extra = extra[2..].to_string();
            }

            // my @tags; my @probs; my @probs_cols = split(/\s+/, $extra);
            let probs_cols: Vec<&str> = extra.split_whitespace().collect();
            let mut tags = Vec::new();
            let mut probs = Vec::new();

            // for (my $i=0; $i < @probs_cols; $i+=2)
            for chunk in probs_cols.chunks(2) {
                if chunk.len() >= 1 {
                    tags.push(chunk[0]);
                }
                if chunk.len() >= 2 {
                    probs.push(chunk[1]);
                }
            }

            // my $xpos = join("|", @tags);
            let xpos = tags.join("|");
            
            // my $misc = (scalar(@tags) == 1) ? "_" : join("|", @probs);
            let misc = if tags.len() == 1 {
                "_".to_string()
            } else {
                probs.join("|")
            };

            // print "$id\t$cols[0]\t$cols[2]\t_\t$xpos\t_\t_\t_\t_\t$misc"
            writeln!(stdout, "{}\t{}\t{}\t_\t{}\t_\t_\t_\t_\t{}", id, cols[0], cols[2], xpos, misc)?;

        } else {
            writeln!(stdout, "{}", line)?;
        }

        buffer.clear();
    }
    Ok(())
}

struct Token {
    word: String,
    tag: String,
    lemma: String,
    rest: Option<String>,
}

enum Line {
    Token(Token),
    Raw(String),
}

fn parse_line(line: &str) -> Line {
    let parts: Vec<&str> = line.split('\t').collect();
    if parts.len() >= 3 {
        Line::Token(Token {
            word: parts[0].to_string(),
            tag: parts[1].to_string(),
            lemma: parts[2].to_string(),
            rest: if parts.len() > 3 { Some(parts[3..].join("\t")) } else { None },
        })
    } else {
        Line::Raw(line.to_string())
    }
}

fn filter_german() -> anyhow::Result<()> {
    let stdin = io::stdin();
    let mut stdout = io::stdout();
    let mut handle = stdin.lock();
    let mut buffer = String::new();

    let mut current_line: Option<Line> = None;
    let mut flag = false;
    let mut zu = false;

    // Regexes
    let re_v_fin_inf = regex::Regex::new(r"V.FIN|V.INF").unwrap();
    let re_punct = regex::Regex::new(r"^[\$][.,]").unwrap();
    let re_word_en = regex::Regex::new(r"[erlu]n$").unwrap();
    let re_word_eten = regex::Regex::new(r"[^aeiou]e*ten$").unwrap();
    let re_zu = regex::Regex::new(r".zu.....").unwrap();
    let re_vvam_fin = regex::Regex::new(r"^V[VAM]FIN$").unwrap();

    // Read first line to populate current_line
    if handle.read_line(&mut buffer)? > 0 {
        let line = buffer.trim_end();
        current_line = Some(parse_line(line));
        buffer.clear();
    }

    while handle.read_line(&mut buffer)? > 0 {
        let line = buffer.trim_end();
        let next_line = parse_line(line);

        if let Some(curr) = current_line {
            match curr {
                Line::Token(mut token) => {
                     let tag_matches = re_v_fin_inf.is_match(&token.tag);
                     let next_is_punct = if let Line::Token(ref next_token) = next_line {
                         re_punct.is_match(&next_token.tag)
                     } else {
                         false
                     };
                     
                     let word_matches = re_word_en.is_match(&token.word) && !re_word_eten.is_match(&token.word) && !re_zu.is_match(&token.word);

                     if tag_matches && next_is_punct && word_matches {
                         if flag || zu {
                             if token.tag == "VVFIN" { token.tag = "VVINF".to_string(); }
                             else if token.tag == "VAFIN" { token.tag = "VAINF".to_string(); }
                             else if token.tag == "VMFIN" { token.tag = "VMINF".to_string(); }
                         } else {
                             if token.tag == "VVINF" { token.tag = "VVFIN".to_string(); }
                             else if token.tag == "VAINF" { token.tag = "VAFIN".to_string(); }
                             else if token.tag == "VMINF" { token.tag = "VMFIN".to_string(); }
                         }
                     }

                     // Update state
                     if re_vvam_fin.is_match(&token.tag) {
                         flag = true;
                     }
                     if re_punct.is_match(&token.tag) {
                         flag = false;
                     }
                     if token.tag == "PTKZU" {
                         zu = true;
                     } else {
                         zu = false;
                     }

                     // Print current
                     if let Some(ref rest) = token.rest {
                         writeln!(stdout, "{}\t{}\t{}\t{}", token.word, token.tag, token.lemma, rest)?;
                     } else {
                         writeln!(stdout, "{}\t{}\t{}", token.word, token.tag, token.lemma)?;
                     }
                },
                Line::Raw(content) => {
                    writeln!(stdout, "{}", content)?;
                }
            }
        }

        current_line = Some(next_line);
        buffer.clear();
    }

    // Process last line
    if let Some(curr) = current_line {
        match curr {
            Line::Token(token) => {
                 if let Some(ref rest) = token.rest {
                     writeln!(stdout, "{}\t{}\t{}\t{}", token.word, token.tag, token.lemma, rest)?;
                 } else {
                     writeln!(stdout, "{}\t{}\t{}", token.word, token.tag, token.lemma)?;
                 }
            },
            Line::Raw(content) => {
                writeln!(stdout, "{}", content)?;
            }
        }
    }

    Ok(())
}
