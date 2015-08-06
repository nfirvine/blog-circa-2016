---
layout: post
title: Paths with ".." are a code smell
date: 2015-08-05
---

I've come to the conclusion that `..` (as in, "give me the parent directory") in file paths is a code smell.

Consider that a code project stored in a directory on a filesystem (call it a "repo") is basically at least directed graph of dependencies: directed because files (inodes) don't reference their parent directories (and indeed may have multiple parents with hardlinks). Is a filesystem acyclic though? Almost.

Modern filesystems support soft links and hard links. Really, hard links are not that special. Since directories map names to inodes in the general case, a hard link is just another record that maps a name to an inode (or subdirectory); the only difference is that it maps to an *existing* inode instead of a new one. There's no distinguishing between the "real" file and the reference: they're both as real as it gets. A soft link is kind of a magic flag that says to filesystem calls that the contents of the file is a reference to something else, and that, depending on the use case, you should probably follow it. So given a soft link and its target, one is clearly real and one is clearly a reference.

Complications abound when we start making cycles. With soft links, you can make cycles without issue. On Linux at least, it's simply disallowed to hard link to a directory. The reason for this difference is that if you allowed hard link cycles, it would be non-trivial to do traversals (recursions) without getting caught in a loop: since any directory could lead to a cycle, you have to keep track of every one you've visited to do cycle detection. With soft link cycles, the problem is limited to keeping visitation records for just the soft links.

The one exception for hard links to directories is `..`. This isn't a problem for filesystem utilities and calls doing traversals because it's simply ignored.

But it's bad idea to use `..` in source code. In a repo, we want to avoid circular dependencies. A source file can depend on sibling directories' descendants without issue. A source file can depend on siblings with some careful engineering: while it's possible to create a cycle between siblings, it should be possible to refactor this to remove the cycle (say by moving the critical code to a third source file). However, if we allow for using `..`, we're almost certainly creating a cycle.

Furthermore, `..` and especially chains like `../../../..` don't exactly lend themselves to readability. Some pattern that walks up until it finds a sentinel file might be slightly better (say `^^.git/config`), as it gives the reader a little context, but has problems of its own (how to handle multiple matches?).

Another problem arises when we need to move directories around: `..`-chains are fragile and unexpected, so if we were to move the directory into a subdirectory, it wouldn't be able to find its dependencies. When you try to fix this, you run into the lack-of-context problem above.

One usage of `..`-chains I've seen is to reach back up to the top level of a project, and then descend down into a different subproject. I would argue this is evidence of a bad build system. Top-level build files should be able to locate dependencies on behalf of deeper files. It's a separations-of-concerns thing.

In summary, the "A" in the dependency DAG is an important property that takes discipline to maintain. Proper trees are significantly easier to reason about.
