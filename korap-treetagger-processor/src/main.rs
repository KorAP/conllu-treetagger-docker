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
    let stdin = io::stdin();
    let stdout = io::stdout();
    let input = stdin.lock();
    let mut output = io::BufWriter::new(stdout.lock());

    match cli.command {
        Commands::Preprocess => preprocess(input, &mut output),
        Commands::Postprocess => postprocess(input, &mut output),
        Commands::FilterGerman => filter_german(input, &mut output),
    }
}

fn preprocess(mut input: impl BufRead, writer: &mut impl Write) -> anyhow::Result<()> {
    let mut buffer = Vec::new();

    while input.read_until(b'\n', &mut buffer)? > 0 {
        let line_cow = String::from_utf8_lossy(&buffer);
        let mut line_string = line_cow.into_owned();
        
        // Replace replacement character with ? to avoid tree-tagger segfaults
        if line_string.contains('\u{FFFD}') {
            line_string = line_string.replace('\u{FFFD}', "?");
        }

        let mut line = line_string.as_str();
        
        // $_=substr($_, 0, 99000);
        if line.len() > 99000 {
            line = &line[..99000];
        }
        
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

        writeln!(writer, "{}", content)?;
        buffer.clear();
    }
    Ok(())
}

fn postprocess(mut input: impl BufRead, writer: &mut impl Write) -> anyhow::Result<()> {
    let mut buffer = Vec::new();
    
    let mut id = 0;

    while input.read_until(b'\n', &mut buffer)? > 0 {
        let line_cow = String::from_utf8_lossy(&buffer);
        // We also sanitize postprocess input just in case, though it should come from tree-tagger
        let line_string = line_cow.replace('\u{FFFD}', "?");
        let mut line = line_string.trim_end().to_string();
        
        // s/^<(.*)>$/$1/
        if line.starts_with('<') && line.ends_with('>') {
            line = line[1..line.len()-1].to_string();
        }

        // s/^(# *foundry *= *)base/$1 tree_tagger/
        if line.starts_with("#") && line.contains("foundry") && line.contains("base") {
             let re = regex::Regex::new(r"^(# *foundry *= *)base").unwrap();
             line = re.replace(&line, "${1}tree_tagger").to_string();
        }

        // $id++; $id=0 if(/^(#|\s*$)/);
        id += 1;
        if line.starts_with('#') || line.trim().is_empty() {
            id = 0;
        }

        // Split by tabs
        let cols: Vec<&str> = line.split('\t').collect();

        // Check if this is the new format with probabilities
        // New format: columns after the first contain spaces (e.g., "TAG lemma prob")
        // Old format: columns are just single values without spaces
        let has_prob_format = cols.len() >= 2 && cols[1..].iter().any(|col| col.contains(' '));

        if !has_prob_format && cols.len() == 3 {
            // Handle simple 3-column format (word, tag, lemma) - no probabilities
             writeln!(writer, "{}\t{}\t{}\t_\t{}\t_\t_\t_\t_\t_", id, cols[0], cols[2], cols[1])?;
        } 
        else if has_prob_format {
            // Handle new format: word \t TAG1 lemma1 prob1 \t TAG2 lemma2 prob2 \t ...
            struct TagLemmaProb {
                tag: String,
                lemma: String,
                prob_str: String,
                prob_val: f64,
            }

            let mut triples: Vec<TagLemmaProb> = Vec::new();

            // First column is the word, remaining columns are "TAG lemma prob" triplets
            for col in &cols[1..] {
                let parts: Vec<&str> = col.split_whitespace().collect();
                
                if parts.len() >= 3 {
                    // Format: TAG lemma prob
                    let tag = parts[0];
                    let lemma = parts[1];
                    let prob_str = parts[2];
                    let prob_val = prob_str.parse::<f64>().unwrap_or(0.0);
                    
                    triples.push(TagLemmaProb {
                        tag: tag.to_string(),
                        lemma: lemma.to_string(),
                        prob_str: prob_str.to_string(),
                        prob_val,
                    });
                } else if parts.len() == 2 {
                    // Fallback: TAG lemma (no prob)
                    let tag = parts[0];
                    let lemma = parts[1];
                    
                    triples.push(TagLemmaProb {
                        tag: tag.to_string(),
                        lemma: lemma.to_string(),
                        prob_str: "1.0".to_string(),
                        prob_val: 1.0,
                    });
                }
            }

            if triples.is_empty() {
                // Fallback to just printing the line as-is
                writeln!(writer, "{}", line)?;
            } else {
                // Sort descending by prob_val
                triples.sort_by(|a, b| b.prob_val.partial_cmp(&a.prob_val).unwrap_or(std::cmp::Ordering::Equal));

                let tags: Vec<String> = triples.iter().map(|t| t.tag.clone()).collect();
                let lemmas_sorted: Vec<String> = triples.iter().map(|t| t.lemma.clone()).collect();
                let probs: Vec<String> = triples.iter().map(|t| t.prob_str.clone()).collect();

                // Join tags with |
                let xpos = tags.join("|");
                
                // Deduplicate lemmas if all are the same
                let unique_lemmas: std::collections::HashSet<String> = lemmas_sorted.iter().cloned().collect();
                
                let lemma_str = if unique_lemmas.len() == 1 {
                    lemmas_sorted[0].clone()
                } else {
                    lemmas_sorted.join("|")
                };
                
                // If only one tag, use "_" for misc, otherwise join probabilities
                let misc = if tags.len() == 1 {
                    "_".to_string()
                } else {
                    probs.join("|")
                };

                // Output: id \t word \t lemma \t _ \t xpos \t _ \t _ \t _ \t _ \t misc
                writeln!(writer, "{}\t{}\t{}\t_\t{}\t_\t_\t_\t_\t{}", id, cols[0], lemma_str, xpos, misc)?;
            }
        } else {
            writeln!(writer, "{}", line)?;
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

fn filter_german(mut input: impl BufRead, writer: &mut impl Write) -> anyhow::Result<()> {
    let mut buffer = Vec::new();

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
    if input.read_until(b'\n', &mut buffer)? > 0 {
        let line_cow = String::from_utf8_lossy(&buffer);
        let line = line_cow.trim_end();
        current_line = Some(parse_line(line));
        buffer.clear();
    }

    while input.read_until(b'\n', &mut buffer)? > 0 {
        let line_cow = String::from_utf8_lossy(&buffer);
        let line = line_cow.trim_end();
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
                         writeln!(writer, "{}\t{}\t{}\t{}", token.word, token.tag, token.lemma, rest)?;
                     } else {
                         writeln!(writer, "{}\t{}\t{}", token.word, token.tag, token.lemma)?;
                     }
                },
                Line::Raw(content) => {
                    writeln!(writer, "{}", content)?;
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
                     writeln!(writer, "{}\t{}\t{}\t{}", token.word, token.tag, token.lemma, rest)?;
                 } else {
                     writeln!(writer, "{}\t{}\t{}", token.word, token.tag, token.lemma)?;
                 }
            },
            Line::Raw(content) => {
                writeln!(writer, "{}", content)?;
            }
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_preprocess_invalid_utf8() {
        let input = b"invalid \xFF utf8\n";
        let mut output = Vec::new();

        preprocess(&input[..], &mut output).unwrap();

        let output_str = String::from_utf8(output).unwrap();
        // invalid \xFF utf8 -> invalid ? utf8
        assert!(output_str.contains("invalid ? utf8"));
    }

    #[test]
    fn test_postprocess_invalid_utf8() {
         let input = b"invalid \xFF utf8\n";
         let mut output = Vec::new();

         postprocess(&input[..], &mut output).unwrap();

         let output_str = String::from_utf8(output).unwrap();
         assert!(output_str.contains("invalid ? utf8"));
    }
}
