# F4attack: Proof-of-Concept Attack Implementation on the Fantastic Four Protocol in MP-SPDZ

This repository is a fork of [MP-SPDZ v0.4.2](https://github.com/data61/MP-SPDZ/tree/v0.4.2) that
minimally alters the behavior of one malicious party in the actively secure MPC protocol
[Fantastic Four](https://eprint.iacr.org/2020/1330) to break the privacy of the protocol. This
serves as proof of concept of our attacks on delayed consistency checks on multiple MPC protocols
designed for active security.

**Check out [our paper](https://eprint.iacr.org/2026/234), accepted at Eurocrypt'26**, for details
and the description of the attack implemented here and attacks on other protocols (Trident, SWIFT,
Quad).

## :warning: Ethical Considerations

This repository provides code for a concrete attack on an MPC protocol, exploiting a vulnerability
of that protocol. Hence, we need to carefully minimize and analyze the risks of disclosing this
code. We take the following into consideration:

* We have followed a responsible disclosure process, where we informed the involved maintainers
about the vulnerability and coordinated with them that the vulnerabilities were closed before
disclosure of our paper and this code.
* Hence, the vulnerability in MP-SPDZ has been fixed in
[commit 85307a1](https://github.com/data61/MP-SPDZ/commit/85307a1b6e50188975b564fbc012c6114d209fd6)
/ [version TBA]() before this repository was made public, and maintainers of other affected
implementations of vulnerable protocols (that we are aware of) have also deployed fixes.
* Still, it can not be excluded that outdated, vulnerable versions are being used. Yet, the
following holds:
* MP-SPDZ contains a disclaimer that it should not be used in critical production, but is aimed to
compare protocol performance.
* Our implementation is specific to computing one certain minimal example function, simply
multiplying three integers, not linked to any specific application. We **do not** provide more
general tooling for extending the attack beyond this specific function.
* Our implementation also does not make it significantly simpler to implement attacks on other
functions, following the results in our paper.

We come to the conclusion that this implementation cannot be deployed as is for exploiting any
vulnerability in outdated code (as it is specific to an artificial, minimal example), while
providing only insignificant assistance in developing more sophisticated exploits. Hence, we opt to
publish it.

## Running the Attack (via Docker)

We recommend running our code using Docker to simplify setup of the MP-SPDZ dependencies and
toolchain. The following steps only require Docker to be running on the host system. Run the
following from within the root directory of this repository:

```sh
# Build the container from the provided dockerfile:
sudo docker build -t f4attack .
# Run the container:
sudo docker run -it -v $(pwd):$(pwd) -w $(pwd) f4attack
# Set up required toolchain for MP-SPDZ:
make setup
# Create certificates for 4 parties:
Scripts/setup-ssl.sh 4
# Compile the minimal example circuit to MP-SPDZ bytecode:
./compile.py attackable_demo_circuit
# Compile the (modified) Fantastic Four protocol:
make -j8 rep4-ring-party.x
```

In the following, the example circuit compiled before where party P2 has no inputs or outputs, i.e.,
should not learn anything, malicious P2 will deviate from the protocol to check if an input named
```d```, provided by party P3, equals ```42``` or does not.

**Error messages and crashing parties are to be expected, as cheating P2 always causes an abort:**
In all cases, some parties will detect the deviation, and will abort the protocol execution. In this
case, MP-SPDZ kills the corresponding process, leading to other parties which did not detect an
inconsistency (yet) crashing as they loose connection to the aborting party. This is per the design
of MP-SPDZ which does not necessarily gracefully terminate a party in case of an abort.

What matters is that, before potentially crashing, P2 will be able to successfully output if the
input of P3 was ```42``` or not. Please continue with the following commands. The output will end
with a summary, showing that the parties abort (throwing some error) and, more importantly,
containing the specified input ```d``` by P3, P2's prediction that ```d=42```, and P2's extracted
info telling if this prediction was correct.

```sh
# Evaluate the example circuit with P3 providing input d=1 (the used argument):
# (errors and crashes in the CLI output are expected, see explanation above)
./run_f4_attack.sh 1
# In the outputs, observe that
# - The parties abort, either because of a hash mismatch or due to being disconnected
#     from another aborting party.
# - Corrupt P2 adds an offset of +1 to one message, guesses that d=42, and notices that
#     this was incorrect (as d=1).
# - (You may scroll up in the CLI output to view the full output of all parties.)

# Evaluate the example circuit with P3 providing input d=42 (the used argument):
# (errors and crashes in the CLI output are expected, see explanation above)
./run_f4_attack.sh 42
# In the outputs, observe that
# - The parties abort, either because of a hash mismatch or due to being disconnected
#     from another aborting party.
# - Corrupt P2 adds an offset of +1 to one message, guesses that d=42, and notices that
#     this guess was correct!
# - (You may scroll up in the CLI output to view the full output of all parties.)

# You may also try for other (sufficiently small, to fit in the default computation
# domain) integers which leads to the same behavior as the case d = 1.

# Overall, corrupt P2 is able to distinguish between P3 having input d=42 and input d!=42.
```

Example outputs:
For ```./run_f4_attack.sh 1```:
```
P0 inputs a = 4
P1 inputs b = 8
P3 inputs d = 1

Starting P0, P1, P2, P3 ...
P1, P2, P3, P4 finished

[OMITTING FULL CLI OUTPUTS OF ALL PARTIES HERE]

######################
### Attack Summary ###
######################
# All parties abort due to failing consistency checks caused by cheating:
# (In MP-SPDZ, an aborting party simply crashes, either directly due to a
# hash mismatch or loosing connection to another aborting party)
P0 error:   what():  read_some: Connection reset by peer [system:104]
P1 error: Fatal error at attackable_demo_circuit-0:3 (0xad): hash mismatch for sender 2 and backup 3
P2 error: Fatal error at attackable_demo_circuit-0:3 (0xad): hash mismatch for sender 1 and backup 3
P3 error:   what():  write_some: Broken pipe [system:32]

# P3 gave input:
d = 1
# Malicious P2 cheated, made a guess for d and checked if correct:
Cheating by adding offset +1 to outgoing message!
Guessing that d=42...
Prior guess for d was not correct.

# (scroll up for full CLI output of each party)
```
For ```./run_f4_attack.sh 42```:
```
P0 inputs a = 4
P1 inputs b = 8
P3 inputs d = 42

Starting P0, P1, P2, P3 ...
P1, P2, P3, P4 finished

[OMITTING FULL CLI OUTPUTS OF ALL PARTIES HERE]

######################
### Attack Summary ###
######################
# All parties abort due to failing consistency checks caused by cheating:
# (In MP-SPDZ, an aborting party simply crashes, either directly due to a
# hash mismatch or loosing connection to another aborting party)
P0 error:   what():  read_some: Connection reset by peer [system:104]
P1 error: Fatal error at attackable_demo_circuit-0:3 (0xad): hash mismatch for sender 2 and backup 3
P2 error: Fatal error at attackable_demo_circuit-0:3 (0xad): hash mismatch for sender 1 and backup 3
P3 error:   what():  write_some: Broken pipe [system:32]

# P3 gave input:
d = 42
# Malicious P2 cheated, made a guess for d and checked if correct:
Cheating by adding offset +1 to outgoing message!
Guessing that d=42...
Prior guess for d was correct!

# (scroll up for full CLI output of each party)
```

Testing for another ```d``` than ```42``` can also be achieved if desired. For that, in
[Protocols/Rep4.hpp](Protocols/Rep4.hpp), change the value of ```d_test``` in line 227 and
recompile (```make -j8 rep4-ring-party.x```) before running ```./run_f4_attack.sh [d]``` again.

## Details and Explanation:

First, we note that in our paper, the parties are named P1, P2, P3, P4. Yet, in the MP-SPDZ
implementation, naming P0, P1, P2, P3 is used which we will also use throughout this codebase as it
modifies MP-SPDZ.

All code modifications to the original
[MP-SPDZ v0.4.2](https://github.com/data61/MP-SPDZ/tree/v0.4.2) are between annotation comments
```F4attack-changes: [...]``` and ```end of F4attack-changes``` to make it easy to search where we
differ from the original implementation. We proceed to describe the important modifications (there
exist minor other QOL modifications which do not alter the protocol behavior like, e.g., the script
[run_f4_attack.sh](run_f4_attack.sh) to automatically set the inputs of all parties and run their
processes). Outside of these modifications, we provide no additional documentation as this is
unchanged code and documentation from the original MP-SPDZ implementation.
**Our attack implementation only consists of all the changes annotated with the aforementioned comments!**
Besides everything enclosed by ```F4attack-changes: [...]``` and ```end of F4attack-changes```, the
only other changes to files are this README file replacing the original one of MP-SPDZ, and the
License where we prepend a paragraph regarding our changes.

First, [Programs/Source/attackable_demo_circuit.mpc](Programs/Source/attackable_demo_circuit.mpc)
implements our circuit from Fig. 2 in [our paper](https://eprint.iacr.org/2026/234) in MP-SPDZ.
Inputs a, b, d are provided by P0, P1, P3, and c = a * b and e = c * d are computed, after which e
is disclosed to P0. It is easy to see that P2 should learn nothing about any inputs or
(intermediate) results.

Now, the changes in [Protocols/Rep4.h](Protocols/Rep4.h) and
[Protocols/Rep4.hpp](Protocols/Rep4.hpp) change the behavior of a corrupt P2 (P3 in the paper) to
carry out the attack shown in §4 and Fig. 8 in [our paper](https://eprint.iacr.org/2026/234). To
recap the attack: Corrupt P2 (we use the party numbering in MP-SPDZ) adds an offset of +1 to its
message towards P1 in the first multiplication c = a * b. In the second multiplication e = c * d, P2
then receives an offset of +d^2 (d^3 in the paper due to other party numbering) on the message that
it receives from P1, caused by the prior offset given to P1. Yet, in the consistency check, it
receives a hash from P3 that does not contain this offset. Finally, corrupt P2 can check for any
value d' by computing the matching d'^2 as it already knows all other shares by design of the
protocol, and subtracting it from the offset message received by P1 before feeding it into the hash
to compare to the hash provided by P3. If both match, the d^2=d'^2 and P2 has learned that d=d'.

This is reflected in our code modifications as follows:
* Inside ```void Rep4<T>::prepare_joint_input``` (which populates the message buffers before message
exchange, joint input is a primitive used by each multiplication), we modify the behavior of corrupt
P2: For the first multiplication, in the message that it sends to P1, it adds the offset to the
value to be sent beforehand and later removes it again from its local state. We note that vector
```inputs``` only contains a single value here, as there is only one multiplication on the first
multiplicative layer: c = a * b.
* Inside ```void Rep4<T>::finalize_joint_input``` (which handles incoming messages after a message
exchange), we again modify the behavior of corrupt P2: This happens only for the second
multiplication, for the value sent by P1 to P2 with P3 later providing the corresponding hash in the
consistency check. We note that parameter ```malicious``` was not introduced by us, but is native to
MP-SPDZ at this location. Here, P2 defines ```d_test=42```, the value of d that our attack is
testing for. It could also be changed to any other test value here in the code it desired, requiring
to recompile with ```make -j8 rep4-ring-party.x```. As described above, the according share d'^2 is
computed as the missing share that the other shares that P2 holds would sum up with together to
```d_test=42```. As explained above, this d'^2 is subtracted from the message received from P1
before feeding the result into the corresponding hash to later be compared to the one received from
P3. Directly below the changed code, find for comparison how the hash is normally populated without
modifying the received message, while also, our modified code is specifically being written for a
single value being received as per our demo circuit, for simplicity.
* Inside ```void Rep4<T>::prepare_mul``` (which runs at the start of each multiplication), corrupt
P2 for the second multiplication saves its shares of the second input (d as we compute e = c * d) to
```F4attack_val_d```. This simply is for internal bookkeeping, allowing these shares to be easily
read by our modification inside ```void Rep4<T>::finalize_joint_input```.
* Inside ```T Rep4<T>::finalize_mul``` (which runs at the end of each multiplication), corrupt P2
increases its multiplication counter. This simply is so that for the specific attacked circuit, we
can distinguish at other locations in the code between the first multiplication c = a * b when an
offset needs to be injected, and the second multiplication e = c * d when the incoming offset
message is being processed.
* ```void Rep4<T>::must_check()``` runs the consistency check. We add a cout here to later verify in
the CLI outputs that indeed, the check does only run after the second multiplication, when P2 is
testing for d = 42. Furthermore, if the consistency check run by P2 for the value received from P1
and hash from P3 succeeds, i.e., the hashes match, we know that the guess d = 42 was correct and
print an according message. Otherwise, d != 42 and we also print a message for that.
* Other modifications in Rep4.h and Rep4.hpp only declare and initialize the bookkeeping variable
which are written and read to exclusively by corrupt P2.

## Limitations

Our attack implementation is limited to one specific circuit, which is first for simplicity, as this
serves as the minimal example to break the protocol's privacy, and second, as we do not intend to
provide a universal tool to exploit vulnerable MP-SPDZ versions. We also just check for one specific
value of d which is the simplest variant of our attack. Following the more general template from
§3.3 in [our paper](https://eprint.iacr.org/2026/234), one could also test for multiple possible
values. Again, our minimal example suffices to demonstrate the vulnerability. Furthermore, only
running one check enables to repurpose the hash comparison already done by P2 in MP-SPDZ, minimizing
the required changes to the original codebase.

## Building Without Docker

If you prefer to build MP-SPDZ including our attack without using Docker, please follow the
corresponding instructions in [MP-SPDZ v0.4.2](https://github.com/data61/MP-SPDZ/tree/v0.4.2). In
short, the requirements are (copied and shortened from the README of MP-SPDZ):

* GCC 7 or later (tested with up to 14) or LLVM/clang 11 or later (tested with up to 20)
* CMake of version at least 3.15
* GMP library, compiled with C++ support, tested against 6.2.1
* libsodium library, tested against 1.0.18
* OpenSSL, tested against 3.0.2
* boost of version at least 1.75
* Boost.Asio with SSL support (`libboost-dev` on Ubuntu), tested against 1.83
* Boost.Thread for BMR (`libboost-thread-dev` on Ubuntu), tested against 1.83
* x86 or ARM 64-bit CPU (the latter tested with AWS Gravitron and Apple Silicon)
* Python 3.5 or later
* NTL library, tested with NTL 11.5.1
* If using macOS, Sierra or later
* Windows/VirtualBox: see [here](https://github.com/data61/MP-SPDZ/issues/557) for a discussion

Alternatively, our Dockerfile shows the requirements on Ubuntu.

After installing all dependencies, the steps are the same as above, now only excluding those
specific to docker. In short:

```sh
make setup
Scripts/setup-ssl.sh 4
./compile.py attackable_demo_circuit
make -j8 rep4-ring-party.x

./run_f4_attack.sh 1

./run_f4_attack.sh 42
```
