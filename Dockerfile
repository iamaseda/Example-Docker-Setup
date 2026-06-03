# Boilerplate CI/CD-Compatible Dockerfile
# These may be modified to fit your needs. However, typical application containers usually need:
# - A base image (the only true requirement)
# - A working directory (WORKDIR)
# - Dependency installation
# - A startup command
# - Optional build, test, and migration stages

# Use Docker layer caching to optimize your container builds by reusing unmodified image layers from
# previous builds when possible. The structure and ordering of your Dockerfile matter.
# 1. COPY dependency files as early as possible after setting the working directory
# 2. RUN any package manager installs that you need
# 3. COPY the source code

# Be sure to combine any related RUN instructions, and exclude unnecessary assets by adding them to your
# dockerignore. Use multi-stage builds (like this example shows), to separate your build and dev
# environments from the final production environment.

# CI/CD Compatibility
# Because many CI pipelines use ephemeral runners, to preserve layer caching between builds, you will 
# need to explicitly export and import your cache using Docker BuildKit, whether in your yaml file or 
# manually in a custom script. If your CI provider already manages cache persistence between runs for 
# you, you may not need additional cache export/import configuration


# ========================================
# Base (The runtime environment and its valid versions can be selected from Docker Hub)
# ========================================
FROM runtime_environment:version AS base

WORKDIR /project_root_directory

# container-wide installations needed in every stage of development
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# non-root user/group creation. 1001 can be any number that will serve as the group id
RUN groupadd -g 1001 group_name && \
    useradd -u 1001 -g group_name -m -s /bin/bash user_name


# ========================================
# Dependencies (single dependency installation for consistency across stages in this example)
# ========================================
FROM base AS deps

COPY package*.json lockfile_name.extension ./

RUN dependency_installation_command


# ========================================
# Build Phase
# ========================================
FROM deps AS build

COPY . .

RUN build_command


# ========================================
# Development Phase
# ========================================
FROM base AS development

# ENV is a variable that persists after the build stage into the run time.
# ARG variables are only accessible during the image build stage. They can also serve as placeholders
# to be updated at build time.
ENV RUNTIME_ENVIRONMENT_ENV=development

# You have two options when it comes to copying dependencies
# Use the command below if you will be mounting a volume in your compose.yaml
COPY --from=deps /project_root_directory/dependency_directory_or_file ./container_dependency_directory_or_file
COPY --from=deps /project_root_directory/package.json ./
# Use the command below instead if you will not be mounting a volume in your compose.yaml
# COPY . .

# Set the user name or UID to use when running the image in addition to any subsequent instructions 
# that follow this in the Dockerfile.
USER user_name

EXPOSE 3000 9229

# start:dev will need to be configured in your compose.yaml file
CMD ["package_manager", "run", "start:dev"]


# ========================================
# Production (The common pattern is to not use development dependencies)
# ========================================
FROM base AS production

ENV RUNTIME_ENVIRONMENT_ENV=production

COPY --from=deps \
    /project_root_directory/dependency_directory_or_file \
    ./container_dependency_directory_or_file
# If copying as root is your intention
COPY --from=build /project_root_directory/dist ./dist
# If copying as root is not your intention, use one of the two below:
# Option 1: Use COPY --chown when possible.
#   COPY --chown=user_name:group_name --from=build /project_root_directory/dist ./dist
# Option 2: Use chown -R if ownership changes need to be made after files have already been created
#   RUN chown -R user_name:group_name /project_root_directory

COPY package.json ./

USER user_name

# Know that EXPOSE doesn't make the port accessible. It only documents it. You will need Compose port
# mappings or `docker run -p 3000:3000`
EXPOSE 3000

# The image healthcheck will be overridden by a healthcheck defined in compose.yaml. Leave it in the 
# dockerfile for a reusable image approach. Put it in the compose.yaml or another such corresponding file
# for an environment-specific approach
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:3000/health || exit 1

# The command below will be different according to runtime and framework(s) used
CMD ["runtime_environment", "dist/main"]

# ========================================
# Schema Migration (Only necessary if you will be using a database)
# ========================================
# The migration stage is optional, and migration can also simply be run in the production image
FROM deps AS migrate

COPY . .

# migrate-db will need to be defined in your compose.yaml file
CMD ["package_manager", "run", "migrate-db"]

# ========================================
# Test
# ========================================
FROM deps AS test

COPY . .

# test:coverage will need to be defined in your compose.yaml file
CMD ["package_manager", "run", "test:coverage"]

# Last Note: CMD provides default arguments and commands. ENTRYPOINT defines the executable that always
# runs. Generally, you will only need CMD