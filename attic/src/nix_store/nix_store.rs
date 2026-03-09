//! High-level Nix Store interface.

use std::path::{Path, PathBuf};
use std::str::FromStr;

use futures::Stream;

use super::{to_base_name, StorePath, ValidPathInfo};
use crate::error::AtticResult;

/// High-level wrapper for the Unix Domain Socket Nix Store.
pub struct NixStore {
    /// Path to the Nix store itself.
    store_dir: PathBuf,
}

impl NixStore {
    pub fn connect() -> AtticResult<Self> {
        Ok(Self {
            // TODO: Make this method async and call nix-instantiate --raw --eval -E 'builtins.storeDir'
            store_dir: PathBuf::from_str("/nix/store").unwrap(),
        })
    }

    /// Returns the Nix store directory.
    pub fn store_dir(&self) -> &Path {
        &self.store_dir
    }

    /// Returns the base store path of a path, following any symlinks.
    ///
    /// This is a simple wrapper over `parse_store_path` that also
    /// follows symlinks.
    pub fn follow_store_path<P: AsRef<Path>>(&self, path: P) -> AtticResult<StorePath> {
        // Some cases to consider:
        //
        // - `/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-nixos-system-x/sw` (a symlink to sw)
        //    - `eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-nixos-system-x`
        //    - We don't resolve the `sw` symlink since the full store path is specified
        //      (this is a design decision)
        // - `/run/current-system` (a symlink to profile)
        //    - `eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-nixos-system-x`
        // - `/run/current-system/` (with a trailing slash)
        //    - `eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-nixos-system-x`
        // - `/run/current-system/sw` (a symlink to sw)
        //    - `eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-system-path` (!)
        let path = path.as_ref();
        if path.strip_prefix(&self.store_dir).is_ok() {
            // Is in the store - directly strip regardless of being a symlink or not
            self.parse_store_path(path)
        } else {
            // Canonicalize then parse
            let canon = path.canonicalize()?;
            self.parse_store_path(canon)
        }
    }

    /// Returns the base store path of a path.
    ///
    /// This function does not validate whether the path is actually in the
    /// Nix store or not.
    ///
    /// The path must be under the store directory. See `follow_store_path`
    /// for an alternative that follows symlinks.
    pub fn parse_store_path<P: AsRef<Path>>(&self, path: P) -> AtticResult<StorePath> {
        let base_name = to_base_name(&self.store_dir, path.as_ref())?;
        StorePath::from_base_name(base_name)
    }

    /// Returns the full path for a base store path.
    pub fn get_full_path(&self, store_path: &StorePath) -> PathBuf {
        self.store_dir.join(&store_path.base_name)
    }

    /// Creates a NAR archive from a path.
    ///
    /// This is akin to `nix-store --dump`.
    pub fn nar_from_path(
        &self,
        _store_path: StorePath,
    ) -> impl Stream<Item = AtticResult<Vec<u8>>> {
        todo!() as futures::stream::Empty<AtticResult<Vec<u8>>>
    }

    /// Returns the closure of a valid path.
    ///
    /// If `flip_directions` is true, the set of paths that can reach `store_path` is
    /// returned.
    pub async fn compute_fs_closure(
        &self,
        _store_path: StorePath,
        _flip_directions: bool,
        _include_outputs: bool,
        _include_derivers: bool,
    ) -> AtticResult<Vec<StorePath>> {
        todo!()
    }

    /// Returns the closure of a set of valid paths.
    ///
    /// This is the multi-path variant of `compute_fs_closure`.
    /// If `flip_directions` is true, the set of paths that can reach `store_path` is
    /// returned.
    pub async fn compute_fs_closure_multi(
        &self,
        _store_paths: Vec<StorePath>,
        _flip_directions: bool,
        _include_outputs: bool,
        _include_derivers: bool,
    ) -> AtticResult<Vec<StorePath>> {
        todo!()
    }

    /// Returns detailed information on a path.
    pub async fn query_path_info(&self, _store_path: StorePath) -> AtticResult<ValidPathInfo> {
        todo!()
    }
}
