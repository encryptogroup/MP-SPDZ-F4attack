# F4attack-changes: replaced original Dockerfile with minimal one needed for our purposes
FROM ubuntu:24.04

RUN apt update
RUN apt install -y --no-install-recommends automake build-essential clang cmake git libboost-all-dev libclang-dev libgmp-dev libntl-dev libsodium-dev libssl-dev libtool openssl python3 ca-certificates
# end of F4attack-changes
