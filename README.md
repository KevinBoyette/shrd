shrd (system with high reliability design)
====

System that searches a set of files to find files that contain a provided sentence.

====

Example use case: a teacher regularly gives the same writing assignment, and wants
to make sure students do not copy the papers from another student. The teacher makes a
directory for each time she teaches the class, and places the student papers in the corresponding
directory. As the teacher grades a paper, she picks a few distinctive words from
the paper and searches for other papers containing the same words.

====

The system will be modified to simulate a relatively high failure rate
for each component. The failure rate for each function call will be approximately 
λ = 1000000/n 2 per time the function is called, where n is the number of lines 
of code in the function.

===
