#!/usr/bin/env bash
###############################################################################
# Git Worktree Helper for AIEHLC
#
# Manages git worktrees under .worktrees/ for parallel development.
# Each worktree gets its own build/ directory so you can compile and test
# independently on different branches.
#
# Usage: bash script/worktree.sh <command> [args]
#
# Commands:
#   create <branch> [base]    Create worktree + new branch from base (default: main)
#   create-from <branch>      Create worktree from existing local/remote branch
#   list                      List all worktrees
#   remove <branch>           Remove worktree (prompts to delete branch)
#   build <branch>            Run cmake + make in the worktree's build/
#   build-unitest <branch>    Build the unitest binary in the worktree
#   cd <branch>               Print worktree path (use: cd $(bash script/worktree.sh cd <name>))
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKTREES_DIR="${REPO_ROOT}/.worktrees"
LLVM_INSTALL_DIR="/scratch/staff/huaj/llvm-project/build/"

usage() {
    cat <<'EOF'
Usage: bash script/worktree.sh <command> [args]

Commands:
  create <branch> [base]    Create worktree + new branch from base (default: main)
  create-from <branch>      Create worktree from existing local/remote branch
  list                      List all worktrees
  remove <branch>           Remove worktree (prompts to delete branch)
  build <branch>            Run cmake + make in the worktree's build/
  build-unitest <branch>    Build the unitest binary in the worktree
  cd <branch>               Print worktree path

Examples:
  bash script/worktree.sh create fix-routing main
  bash script/worktree.sh create-from routingbrokenbug
  bash script/worktree.sh build fix-routing
  bash script/worktree.sh remove fix-routing
  cd $(bash script/worktree.sh cd fix-routing)
EOF
}

ensure_worktrees_dir() {
    if [ ! -d "${WORKTREES_DIR}" ]; then
        mkdir -p "${WORKTREES_DIR}"
    fi
}

worktree_path() {
    local branch="$1"
    echo "${WORKTREES_DIR}/${branch}"
}

cmd_create() {
    local branch="${1:?Error: branch name required}"
    local base="${2:-main}"

    ensure_worktrees_dir

    local wt_path
    wt_path="$(worktree_path "${branch}")"

    if [ -d "${wt_path}" ]; then
        echo "Error: worktree already exists at ${wt_path}"
        exit 1
    fi

    echo "Creating worktree for new branch '${branch}' based on '${base}'..."
    git -C "${REPO_ROOT}" worktree add -b "${branch}" "${wt_path}" "${base}"

    echo ""
    echo "Worktree created at: ${wt_path}"
    echo "Branch: ${branch} (based on ${base})"
    echo ""
    echo "Next steps:"
    echo "  cd ${wt_path}"
    echo "  bash script/worktree.sh build ${branch}"
}

cmd_create_from() {
    local branch="${1:?Error: branch name required}"

    ensure_worktrees_dir

    local wt_path
    wt_path="$(worktree_path "${branch}")"

    if [ -d "${wt_path}" ]; then
        echo "Error: worktree already exists at ${wt_path}"
        exit 1
    fi

    # Check if branch exists locally
    if git -C "${REPO_ROOT}" show-ref --verify --quiet "refs/heads/${branch}" 2>/dev/null; then
        echo "Creating worktree from existing local branch '${branch}'..."
        git -C "${REPO_ROOT}" worktree add "${wt_path}" "${branch}"
    # Check if branch exists on remote
    elif git -C "${REPO_ROOT}" show-ref --verify --quiet "refs/remotes/origin/${branch}" 2>/dev/null; then
        echo "Creating worktree from remote branch 'origin/${branch}'..."
        git -C "${REPO_ROOT}" worktree add --track -b "${branch}" "${wt_path}" "origin/${branch}"
    else
        echo "Error: branch '${branch}' not found locally or on origin"
        echo "Available branches:"
        git -C "${REPO_ROOT}" branch -a
        exit 1
    fi

    echo ""
    echo "Worktree created at: ${wt_path}"
    echo "Branch: ${branch}"
    echo ""
    echo "Next steps:"
    echo "  cd ${wt_path}"
    echo "  bash script/worktree.sh build ${branch}"
}

cmd_list() {
    echo "Git worktrees:"
    echo ""
    git -C "${REPO_ROOT}" worktree list
}

cmd_remove() {
    local branch="${1:?Error: branch name required}"

    local wt_path
    wt_path="$(worktree_path "${branch}")"

    if [ ! -d "${wt_path}" ]; then
        echo "Error: no worktree found at ${wt_path}"
        exit 1
    fi

    echo "Removing worktree at ${wt_path}..."
    git -C "${REPO_ROOT}" worktree remove "${wt_path}" --force

    echo "Worktree removed."

    # Ask about branch deletion (skip in non-interactive mode)
    if git -C "${REPO_ROOT}" show-ref --verify --quiet "refs/heads/${branch}" 2>/dev/null; then
        if [ -t 0 ]; then
            read -r -p "Also delete branch '${branch}'? [y/N] " answer
            if [[ "${answer}" =~ ^[Yy]$ ]]; then
                git -C "${REPO_ROOT}" branch -D "${branch}"
                echo "Branch '${branch}' deleted."
            else
                echo "Branch '${branch}' kept."
            fi
        else
            echo "Branch '${branch}' kept (non-interactive mode; delete manually with: git branch -D ${branch})"
        fi
    fi
}

cmd_build() {
    local branch="${1:?Error: branch name required}"

    local wt_path
    wt_path="$(worktree_path "${branch}")"

    # Allow building in main repo too
    if [ "${branch}" = "main" ] && [ ! -d "${wt_path}" ]; then
        wt_path="${REPO_ROOT}"
    fi

    if [ ! -d "${wt_path}" ]; then
        echo "Error: no worktree found at ${wt_path}"
        echo "Create one first: bash script/worktree.sh create ${branch}"
        exit 1
    fi

    local build_dir="${wt_path}/build"
    mkdir -p "${build_dir}"

    echo "Building in ${build_dir}..."
    echo "LLVM_INSTALL_DIR=${LLVM_INSTALL_DIR}"

    cd "${build_dir}"
    cmake .. -DLLVM_INSTALL_DIR="${LLVM_INSTALL_DIR}"
    make -j"$(nproc)"

    echo ""
    echo "Build complete: ${build_dir}"
}

cmd_build_unitest() {
    local branch="${1:?Error: branch name required}"

    local wt_path
    wt_path="$(worktree_path "${branch}")"

    # Allow building in main repo too
    if [ "${branch}" = "main" ] && [ ! -d "${wt_path}" ]; then
        wt_path="${REPO_ROOT}"
    fi

    if [ ! -d "${wt_path}" ]; then
        echo "Error: no worktree found at ${wt_path}"
        echo "Create one first: bash script/worktree.sh create ${branch}"
        exit 1
    fi

    local unitest_dir="${wt_path}/src/mlir/mlirfront/tilinglinalg/pass/unitest"
    local build_dir="${unitest_dir}/build"

    if [ ! -d "${unitest_dir}" ]; then
        echo "Error: unitest directory not found at ${unitest_dir}"
        exit 1
    fi

    mkdir -p "${build_dir}"

    echo "Building unitest in ${build_dir}..."

    cd "${build_dir}"
    cmake ..
    make -j"$(nproc)"

    echo ""
    echo "Unitest build complete: ${build_dir}"
    echo "Run: ${build_dir}/test"
}

cmd_cd() {
    local branch="${1:?Error: branch name required}"

    local wt_path
    wt_path="$(worktree_path "${branch}")"

    if [ ! -d "${wt_path}" ]; then
        echo "Error: no worktree found at ${wt_path}" >&2
        exit 1
    fi

    # Print just the path (stdout) so it can be used with: cd $(bash script/worktree.sh cd <name>)
    echo "${wt_path}"
}

# --- Main dispatch ---

command="${1:-}"
shift || true

case "${command}" in
    create)
        cmd_create "$@"
        ;;
    create-from)
        cmd_create_from "$@"
        ;;
    list)
        cmd_list
        ;;
    remove)
        cmd_remove "$@"
        ;;
    build)
        cmd_build "$@"
        ;;
    build-unitest)
        cmd_build_unitest "$@"
        ;;
    cd)
        cmd_cd "$@"
        ;;
    -h|--help|help|"")
        usage
        ;;
    *)
        echo "Error: unknown command '${command}'"
        echo ""
        usage
        exit 1
        ;;
esac
