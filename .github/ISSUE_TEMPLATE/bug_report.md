---
name: Bug report
about: Create a report to help us improve
title: ''
labels: ''
assignees: ''

---

**System Information**
 - example: Frontier

**OMPI-X Release Version**
 - example: ompix-a1

**Short description of error**

**Exact steps for others to reproduce the error**

Run the following test with N node allocation...

```
 mpirun --bind-to core --map-by ppr:1:l3cache --np 16 ./osu_alltoall
```

-----------------------------

**Other details**

*Note*: If you include verbatim output (or a code block), please use a [GitHub Markdown](https://help.github.com/articles/creating-and-highlighting-code-blocks/) code block like below:

```shell
shell$ mpirun --np 2 ./a.out
```
