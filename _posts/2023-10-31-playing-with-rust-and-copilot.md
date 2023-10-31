---
title: Playing with Rust and Copilot
categories: ['software development']
date: 2023-10-31
tags: [rust,copilot,genai]
classes: wide
toc: false
---
The world is full of AI hype aright now - and often it's blown out of proportion, both on the "everything is fine" side and the "machines are going to take over" side.  I don't have time to write about my opinions on this properly!

I just thought I'd post my brief experience of tinkering with [Github Copilot](https://github.com/features/copilot) and a bit of simple rust code.

I have no interest in letting AIs generate huge amounts of code - that seems like a path to bloat and technical debt in my mind.  But I can see value in using AIs like a slightly smarter autocomplete - and I thought I'd give it a go on some Rust code.  This interested me partly as I like Rust - but also as it's a fairly new language so Copilot can't just slurp down vast amounts of other people's code.

My problem is simple - I want to parse some markdown with frontmatter yaml data - stuff like:

```md
---
title: 'my amazing file'
foo: bar
---
everything is _awesome_
```

I had some old code that wrote files like this, but nothing to read them, so I thought I'd take my existing structs as a starting point:

```rust
#[derive(Serialize, Deserialize, Debug)]
pub struct Metadata {
    pub title: String,
    #[serde(flatten)]
    pub extra_fields: HashMap<String, Value>,
}

#[derive(Debug, Clone)]
pub struct MarkdownFile {
    pub path: PathBuf,
    pub front_matter: Metadata,
    pub body: Vec<String>,
}

impl MarkdownFile {
}
```

Inside the implementation I typed:

```rust
pub fn read(
```

and it magically suggested a function:

```rust
pub fn read(path: PathBuf) -> Result<Self> {
    let contents = std::fs::read_to_string(&path)?;
    let (front_matter, body) = Self::split_front_matter(&contents)?;
    let front_matter: Metadata = serde_yaml::from_str(&front_matter)?;
    Ok(Self {
        path,
        front_matter,
        body,
    })
}
```

This doesn't work immediately, but that's fine - it's good enough:

- the function signature was OK (probably should be `&Path` though)
- it reminded me how to slurp a file as a string
- It suggested how to split the file into two parts (the `split_front_matter` function doesn't exist - it's just a suggestion)
- It worked out that I wanted to get the front matter as YAML. I didn't specify that - it must have inferred that from other markdown-parsing code.

I could have written all that myself, but it saved me some boilerplate typing, and guessing at API signatures.

However - then I asked it to generate `split_front_matter`:

```rust
pub fn split_front_matter(contents: &str) -> Result<(String, Vec<String>)> {
    let mut lines = contents.lines();
    let mut front_matter = String::new();
    let mut body = Vec::new();
    let mut in_front_matter = false;
    while let Some(line) = lines.next() {
        if line == "---" {
            if in_front_matter {
                break;
            } else {
                in_front_matter = true;
            }
        } else if in_front_matter {
            front_matter.push_str(line);
            front_matter.push('\n');
        } else {
            body.push(line.to_string());
        }
    }
    Ok((front_matter, body))
}
```

This was less good. It doesn't work! (I wrote a unit test to prove this - I wonder if Copilot would have done better if I'd TDD'd it?).  Like a lot of AI generated stuff, it _looks_ OK - confidently OK - but the `break` is wrong, it should be setting `in_front_matter` to false.  Also it doesn't handle several edge cases like `---` inside the markdown body.

Also it's pretty ugly C-style procedural code.  You can do this much more nicely with some iterators and splitting:[^1]

[^1]: I also added error checking, a more flexible `contents` parameter, and a minor cheat - I used `collect_tuple` from the itertools crate rather than doing more messy iterator-to-variable processing

```rust
pub fn split_front_matter(contents: impl AsRef<str>) -> Result<(String, Vec<String>)> {
    let Some((prefix, frontmatter, body)) =
        contents.as_ref().splitn(3, "---\n").collect_tuple()
    else {
        return Err(anyhow!("No front matter"));
    };
    if prefix != "" {
        return Err(anyhow!("text before front matter!"));
    }
    Ok((
        frontmatter.to_string(),
        body.lines().map(|s| s.to_string()).collect(),
    ))
}
```

My conclusion so far from this tiny sample - Copilot is handy for this for a minor IDE boost for simple boilerplate code, but definitely not to be trusted for anything longer; at least not in rust.
