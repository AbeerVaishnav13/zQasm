// Source: https://github.com/Qiskit/openqasm
// quantum teleportation example
OPENQASM 3;
include "stdgates.inc";

qubit[3] q;
bit c0;
bit c1;
bit c2;
duration t = 100ms;
bool b = true;

// optional post-rotation for state tomography
// empty gate body => identity gate
gate post q { }
reset q;

// Create Psi qubit
U(0.3, 0.2, 0.1) q[0];

// Create bell pair for Alice and Bob
h q[1];
cx q[1], q[2];
barrier q;

// Apply Bell measurement
cx q[0], q[1];
h q[0];
c0 = measure q[0];
c1 = measure q[1];

// Apply classical post-processing
if(c0==1) z q[2];
if(c1==1) { x q[2]; }  // braces optional in this case
if (c0 & c1) { h q[2]; }

// Measure Bob qubit
c2 = measure q[2];
