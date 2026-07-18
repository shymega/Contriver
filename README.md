# Contriver

A fault-tolerant REAPI and CAS implementation, written in Elixir, designed for high-availability, speed, and ease-of-use.

## Aims

- Built-in distribution logic - distributed builds and REAPI will be well-integrated with Contriver, and able to spread builds across many hosts.
- Compatibility with Buildbox, and a drop-in replacement for use with clients like BuildStream, or Bazel.
- Full compliance with the Remote Execution API.
- Resilience against faults - able to use multiple storage backends, and when a build worker goes down, Contriver will switch to another worker, and try to resume the build.
- Speed and delivery reliance is a top priority. We want this to be the fastest CAS and REAPI server out there.
