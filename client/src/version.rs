/// The distributor of this Attic client.
///
/// Common values include `nixpkgs`, `attic` and `dev`.
pub const CELLER_DISTRIBUTOR: &str = if let Some(distro) = option_env!("CELLER_DISTRIBUTOR") {
    distro
} else {
    "unknown"
};
