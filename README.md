# CI/CD-Compatible Dockerfile

## General Structure
These may be modified to fit your needs. However, typical application containers usually need:
 - A base image (the only true requirement)
 - A working directory (WORKDIR)
 - Dependency installation
 - A startup command
 - Optional build, test, and migration stages

## Docker Layer Caching - Build Optimization
Use Docker layer caching to optimize your container builds by reusing unmodified image layers from
previous builds when possible. The structure and ordering of your Dockerfile matter.
1. COPY dependency files as early as possible after setting the working directory
2. RUN any package manager installs that you need
3. COPY the source code

Be sure to combine any related RUN instructions, and exclude unnecessary assets by adding them to your
dockerignore. Use multi-stage builds (like this example shows), to separate your build and dev
environments from the final production environment.

## CI/CD Compatibility
Because many CI pipelines use ephemeral runners, to preserve layer caching between builds, you will 
need to explicitly export and import your cache using Docker BuildKit, whether in your yaml file or 
manually in a custom script. If your CI provider already manages cache persistence between runs for 
you, you may not need additional cache export/import configuration
