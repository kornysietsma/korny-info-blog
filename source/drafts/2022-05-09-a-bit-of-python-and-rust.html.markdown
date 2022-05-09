---

title: A bit of python and rust
date: 2022-05-09 09:52 GMT
tags: 

---
I have been doing some code tinkering lately and happened to want to do something very similar in Python and in Rust, and I thought it was interesting to compare them.

Note I deliberately avoided titling this "python vs rust" !  They are both great languages with quite different sweet spots, and which you choose for a task might depend a lot on your own style as well as the kind of task.

Also I'm not an expert on either - I wrote quite a bit of python a long time ago, but haven't really used it heavily since.  And I've written a bunch of rust as well, but only on side projects, and not really those for a few months (yes, I'm a bit rusty)

## The problem

It's pretty simple - I have a set of bookmark files from my personal notes system that are JSON files with a simple enough structure:

```json
[
  {
    "title": "xlcat: like cat, but for Excel files",
    "date": "2021-07-29",
    "categories": ["tech"],
    "tags": ["tech", "spreadsheets", "excel"],
    "lines": ["https://xlpro.tips/posts/xlcat/"]
  },
  {
    "title": "kube-rs",
    "date": "2021-08-04",
    "categories": ["tech"],
    "tags": ["k8s", "kubernetes", "rust"],
    "lines": ["https://github.com/kube-rs"]
  }
]
```

These are in a set of directories and subdirectories, and I wanted to read in every entry from every file and then do some processing.

## Python approach

I'll cut to the chase - here's the Python code:

```python
