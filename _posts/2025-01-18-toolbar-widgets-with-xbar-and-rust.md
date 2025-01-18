---
title: Mac toolbar widgets with xbar and rust
categories: ['software development']
date: 2025-01-18
tags: [mac, rust, xbar, tools]
toc: false
---
(aside - I have some much bigger blog ideas but haven't had the time to write them properly - so here's just a small thing I find handy)

Lately I wanted some toolbar widgets - mostly for looking at CI/CD build statuses - and I stumbled across XBar.

## What is XBar?

[XBar](https://xbarapp.com/) is a nifty tool for Mac OSX machines which puts little UI widgets on your toolbar. (It started as an older project called Bitbar, which was abandoned for a while - there is a similar alternative called [SwiftBar](https://github.com/swiftbar/SwiftBar) for those who want options)

One of the marvellous things about XBar is how very simple it is. It very much follows the "Unix philosophy" - every plugin is a very simple executable script - if it succeeds (e.g. exit status 0) then the STDOUT is parsed and used to display a toolbar widget.  If it fails, then STDOUT is parsed and displayed on an error widget.

So for example a very simple plugin might just be a bash script:

```bash
#!/usr/bin/env bash
echo "Ow!"
echo "---"
echo "this shows up in a dropdown"
echo "Don't click me | shell=\"/usr/bin/say\" param1=\"ow\""
```

If you copy the above to an executable file in `~/Library/Application\ Support/xbar/plugins/ow.1m.sh` and refresh XBar, it will show up as a little drop-down menu:

![screenshot of xbar](/assets/images/2025-01-18-xbar/ow.png)

Click the "Don't click me" button and the command `/usr/bin/say ow` is run.

The script even refreshes itself - based on the file name. In `ow.1m.sh` the `1m` means "re-run this every 1 minute" - so every minute the script is run and the UI is refreshed.

The UI is all based on text - but unicode is supported, so you can do fairly creative things to make it prettier.

## Hang on, you mentioned rust...

Naturally I wanted to do more than can just be done in bash. I really wanted to write plugins in rust - but rust is a compiled language, so it can't really be run as a script, out of the box.

There are some ways around this though.

You _can_ just copy a binary executable into the Plugins folder.  If I compile a rust binary, then copy it to `~/Library/Application\ Support/xbar/plugins/my-thing.1m.o` it will work!  However - XBar does more than just execute the file - it also looks for special comments in the file [to add metadata](https://github.com/matryer/xbar-plugins/blob/main/CONTRIBUTING.md#metadata) - things like the author name, or configuration information. And you can't put comments inside a binary file.

A second thing I tried was to just write a bash plugin which calls my rust code - this works well, but it's a little fiddly. This is actually what I use at work to build node.js plugins with a full `package.json` dependency file.

For rust though I found exactly what I needed - [rust-script](https://rust-script.org/) - which basically allows you to write a script like:

```sh
#!/usr/bin/env rust-script
println!("Hello world!");
```

And then the `rust-script` system will compile the code (if needed - it caches compiled binaries) and run it, like a shell script.

I did have to do one tweak though - XBar doesn't run in a user shell, so `/usr/bin/env` doesn't have access to your path - and `rust-script` is installed by cargo in `~/.cargo/bin` - but you can tell `/usr/bin/env` what path to use with a bit of fiddling.

A very simple rust xbar plugin looks like:

```rust
#!/usr/bin/env -S PATH=/Users/${USER}/.cargo/bin:${PATH} rust-script

println!("Hello world!");
println;("---");
println!("drop down content here");
```

## A proper rust example

This is a more realistic example. I added a `main` function, and a comment block at the top - both to define [XBar metadata](https://github.com/matryer/xbar-plugins/blob/main/CONTRIBUTING.md#metadata) but also to fetch rust dependencies:

```rust
#!/usr/bin/env -S PATH=/Users/${USER}/.cargo/bin:${PATH} rust-script
//! hello-xbar
//! <xbar.title>XBar time</xbar.title>
//! <xbar.author>Korny Sietsma</xbar.author>
//! <xbar.author.github>kornysietsma</xbar.author.github>
//! <xbar.desc>Basic rust xbar sample</xbar.desc>
//! ```cargo
//! [dependencies]
//! chrono = "0.4.39"
//! ```

fn main() {
    let dt = chrono::Local::now();
    let humantime = dt.format("%l %M %p and %S seconds").to_string();

    println!("🕰️");
    println!("---");
    println!("{}", humantime);
    println!("say it! | shell=\"/usr/bin/say\" param1=\"The time is {}\"", humantime);
}
```

This gives a neat little clock widget similar to:

![screeenshot of clock widget](/assets/images/2025-01-18-xbar/time.png)

If you click "say it" a voice reads the time, sort-of.

## A bigger example - mpd-xbar-demo

I also have a more full-featured demo: [mpd-xbar-demo on github](https://github.com/kornysietsma/mpd-xbar-demo)

This lets me do basic controls for [MPD (the Music Player Demon)](https://www.musicpd.org/) which I use to play music at home.

On top of the approaches described above, it adds:

- A cargo.toml project file - not essential, but very helpful to let editors help you with dependencies
- a config setting - xbar allows you to define script configuration in environment variables
- Installation instructions!

Finally be warned - XBar is neat, but sometimes configuration is fiddly. I've had to run `killall -9 xbar` more than once when things got stuck.
