# Dockerfile (CI/CD-Compatible) - General Information ℹ️📝
If you're anything like me, you weren't born with Docker documentation in your hand. Like with anything else, you have to
learn about it. Unfortunately, many articles on Docker, or other similar development documentation, make too many heavy
assumptions about prior knowledge, tell you the 'how' without explaining any of the 'why', or don't break down the why in a
simple way. This repo serves as a place to show you how to containerize your project, explain some
of the context behind why certain things are necessary or traditionally done, and to refresh your memory for next time in
case yours, like mine, isn't photographic.😉

## General Structure 👷🏾‍♂️🧱
### Dockerfile
These may be modified to fit your needs. However, generally, application containers usually need:
 - A base image (the only true requirement)
 - A working directory (`WORKDIR`)
 - Dependency installation
 - A startup command
 - Optional build, test, and migration stages
### Compose
These may be modified to fit your needs. Find out how it works [[here](https://docs.docker.com/compose/intro/compose-application-model/)].
Each section's relevant documentation can be found [[here](https://docs.docker.com/reference/compose-file/)]
### .dockerignore
**Do not exclude files required to build your application.**
For example, Dockerfiles, lockfiles, dependency manifests,and build configuration files are usually required during image creation.

## Docker Layer Caching - Build Optimization 🏎️
Use Docker layer caching to optimize your container builds by reusing unmodified image layers from
previous builds when possible. The structure and ordering of your Dockerfile matter.
1. COPY dependency files as early as possible after setting the working directory
2. RUN any package manager installs that you need
3. COPY the source code

Be sure to combine any related RUN instructions, and exclude unnecessary assets by adding them to your
`.dockerignore`. Use multi-stage builds (as this example shows) to separate your build and dev
environments from the final production environment.

## CI/CD Compatibility ☯️
Because many CI pipelines use ephemeral runners, to preserve layer caching between builds, you will 
need to explicitly export and import your cache using Docker BuildKit, whether in your *.yaml file or 
manually in a custom script. If your CI provider already manages cache persistence between runs, you may not need additional cache export/import configuration.

Visit this link to learn how to configure a [[Continuous Integration workflow](https://docs.github.com/en/actions/get-started/quickstart)] for your project
